import { NextResponse } from "next/server";
import { adminDb } from "@/lib/firebase-admin";
import {
  verifySubscription,
  verifyProduct,
  acknowledgeSubscription,
  mapSubscriptionStatus,
} from "@/lib/google-play";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

// Validate Pub/Sub push token to prevent unauthorized calls.
// Empty token disables the endpoint entirely (auth not configured).
const PUBSUB_TOKEN = process.env.GOOGLE_PUBSUB_TOKEN;
const TOKEN_IS_CONFIGURED = PUBSUB_TOKEN != null && PUBSUB_TOKEN.length > 0;

/**
 * POST /api/webhooks/google-play
 * Receives Real-time Developer Notifications from Google Cloud Pub/Sub.
 * Must always return 200 to prevent infinite Pub/Sub retries.
 */
export async function POST(req: Request) {
  // 1. Validate shared secret token
  if (!TOKEN_IS_CONFIGURED || req.url.includes("token=") === false) {
    console.error(
      "[GooglePlay Webhook] Token not configured or missing in URL.",
    );
    return NextResponse.json(
      { ok: false, reason: "auth_not_configured" },
      { status: 503 },
    );
  }
  const url = new URL(req.url);
  const token = url.searchParams.get("token");
  if (token !== PUBSUB_TOKEN) {
    console.warn("[GooglePlay Webhook] Unauthorized request — invalid token.");
    // Return 200 to ACK the Pub/Sub message and prevent retry storms.
    // A 4xx here would cause Pub/Sub to retry indefinitely.
    return NextResponse.json(
      { ok: false, reason: "unauthorized" },
      { status: 200 },
    );
  }

  let rawBody: any;
  try {
    rawBody = await req.json();
  } catch {
    return NextResponse.json(
      { ok: false, reason: "invalid_body" },
      { status: 200 },
    );
  }

  // 2. Decode base64 Pub/Sub message
  const messageData = rawBody?.message?.data;
  if (!messageData) {
    console.warn(
      "[GooglePlay Webhook] Missing message.data in Pub/Sub payload.",
    );
    return NextResponse.json({ ok: true, reason: "no_data" }, { status: 200 });
  }

  let notification: any;
  try {
    const decoded = Buffer.from(messageData, "base64").toString("utf-8");
    notification = JSON.parse(decoded);
  } catch {
    console.error("[GooglePlay Webhook] Failed to decode Pub/Sub message.");
    return NextResponse.json(
      { ok: true, reason: "decode_error" },
      { status: 200 },
    );
  }

  console.log(
    "[GooglePlay Webhook] Received notification:",
    JSON.stringify(notification),
  );

  const packageName = notification.packageName as string;
  const subscriptionNotification = notification.subscriptionNotification;
  const oneTimeProductNotification = notification.oneTimeProductNotification;

  try {
    if (subscriptionNotification) {
      await handleSubscriptionNotification(
        subscriptionNotification,
        notification,
      );
    } else if (oneTimeProductNotification) {
      await handleOneTimeProductNotification(
        oneTimeProductNotification,
        notification,
      );
    } else {
      console.log(
        "[GooglePlay Webhook] Unhandled notification type:",
        notification,
      );
    }
  } catch (err) {
    console.error("[GooglePlay Webhook] Error processing notification:", err);
    // Still return 200 to prevent Pub/Sub retries
  }

  return NextResponse.json({ ok: true }, { status: 200 });
}

/**
 * Handle subscription lifecycle notifications.
 * Types: PURCHASED=1, RENEWED=2, RECOVERED=3, PAUSED=5, RESTARTED=7,
 *        PRICE_CHANGE=8, DEFERRED=9, ON_HOLD=12, CANCELED=13, EXPIRED=13, GRACE_PERIOD=6
 */
async function handleSubscriptionNotification(notification: any, raw: any) {
  const { purchaseToken, subscriptionId, notificationType } = notification;
  if (!purchaseToken || !subscriptionId) return;

  // Verify purchase with Google Play Developer API
  const subscription = await verifySubscription(subscriptionId, purchaseToken);
  const lineItem = subscription.lineItems?.[0];
  const expiryMillis = lineItem?.expiryTime
    ? new Date(lineItem.expiryTime).getTime()
    : null;
  const status = mapSubscriptionStatus(subscription.subscriptionState);

  // Find userId from obfuscatedExternalAccountId (set by Android app on purchase)
  const userId =
    subscription.externalAccountIdentifiers?.obfuscatedExternalAccountId ||
    null;
  const orderId = subscription.latestOrderId || purchaseToken.slice(0, 40);

  // Upsert payment record
  const paymentRef = adminDb.collection("payments").doc(orderId);
  const paymentData: Record<string, any> = {
    orderId,
    purchaseToken,
    productId: subscriptionId,
    purchaseType: "subscription",
    status,
    autoRenewing:
      subscription.subscriptionState === "SUBSCRIPTION_STATE_ACTIVE",
    expiryTime: expiryMillis ? Timestamp.fromMillis(expiryMillis) : null,
    verifiedAt: FieldValue.serverTimestamp(),
    rawNotification: raw,
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (userId) {
    paymentData.userId = userId;
    // Lookup email
    try {
      const userDoc = await adminDb.collection("users").doc(userId).get();
      if (userDoc.exists) paymentData.userEmail = userDoc.data()?.email || "";
    } catch {}
  }

  const existingDoc = await paymentRef.get();
  if (existingDoc.exists) {
    await paymentRef.update(paymentData);
  } else {
    await paymentRef.set({
      ...paymentData,
      purchaseTime: FieldValue.serverTimestamp(),
      amount: 0,
      currency: "VND",
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  // Acknowledge purchase (required within 3 days)
  try {
    await acknowledgeSubscription(subscriptionId, purchaseToken);
  } catch (err) {
    console.warn(
      "[GooglePlay Webhook] Acknowledge failed (may already be acknowledged):",
      err,
    );
  }

  // Update user VIP status if userId is known
  if (userId) {
    const isPremium = status === "active";
    const userUpdate: Record<string, any> = {
      isPremium,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (isPremium && expiryMillis) {
      userUpdate.premiumExpiry = Timestamp.fromMillis(expiryMillis);
      userUpdate.activeSubscriptionId = orderId;
    } else if (!isPremium) {
      userUpdate.premiumExpiry = null;
      userUpdate.activeSubscriptionId = null;
    }
    await adminDb
      .collection("users")
      .doc(userId)
      .set(userUpdate, { merge: true });
    console.log(`[GooglePlay Webhook] User ${userId} isPremium=${isPremium}`);
  }
}

/**
 * Handle one-time in-app product purchase notifications.
 */
async function handleOneTimeProductNotification(notification: any, raw: any) {
  const { purchaseToken, sku, notificationType } = notification;
  if (!purchaseToken || !sku) return;

  const product = await verifyProduct(sku, purchaseToken);
  const orderId = product.orderId || purchaseToken.slice(0, 40);
  const status = product.purchaseState === 0 ? "active" : "pending";

  const paymentRef = adminDb.collection("payments").doc(orderId);
  await paymentRef.set(
    {
      orderId,
      purchaseToken,
      productId: sku,
      purchaseType: "inapp",
      status,
      amount: 0,
      currency: "VND",
      purchaseTime: FieldValue.serverTimestamp(),
      verifiedAt: FieldValue.serverTimestamp(),
      rawNotification: raw,
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}
