import { NextResponse } from "next/server";
import { adminDb } from "@/lib/firebase-admin";
import {
  verifySubscription,
  acknowledgeSubscription,
  acknowledgeProduct,
  mapSubscriptionStatus,
} from "@/lib/google-play";
import { createHash } from "crypto";
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
 * Key by purchaseToken (stable ID across renewals) instead of latestOrderId
 * (which changes each billing cycle and causes doc duplication/collision).
 *
 * notificationType: PURCHASED=1, RENEWED=2, RECOVERED=3, PAUSED=5, RESTARTED=7,
 *                   PRICE_CHANGE=8, DEFERRED=9, ON_HOLD=12, CANCELED=13, EXPIRED=13, GRACE_PERIOD=6
 */
async function handleSubscriptionNotification(notification: any, raw: any) {
  const { purchaseToken, subscriptionId } = notification;
  if (!purchaseToken || !subscriptionId) return;

  // Stable payment doc ID — purchaseToken stays the same across all renewals
  const paymentDocId = createHash("sha256")
    .update(purchaseToken)
    .digest("hex")
    .slice(0, 40);

  // Verify purchase with Google Play Developer API
  const subscription = await verifySubscription(subscriptionId, purchaseToken);
  const lineItem = subscription.lineItems?.[0];
  const expiryMillis = lineItem?.expiryTime
    ? new Date(lineItem.expiryTime).getTime()
    : null;
  const status = mapSubscriptionStatus(subscription.subscriptionState);

  // autoRenewingPlan: present only when user HAS enabled auto-renew
  // (absent when user has already cancelled — even if sub is still ACTIVE)
  const autoRenewing = !!lineItem?.autoRenewingPlan;

  // Find userId from obfuscatedExternalAccountId (set by Android app on purchase)
  const userId =
    subscription.externalAccountIdentifiers?.obfuscatedExternalAccountId ||
    null;

  // Upsert payment record
  const paymentRef = adminDb.collection("payments").doc(paymentDocId);
  const paymentData: Record<string, any> = {
    purchaseToken,
    productId: subscriptionId,
    purchaseType: "subscription",
    status,
    autoRenewing,
    expiryTime: expiryMillis ? Timestamp.fromMillis(expiryMillis) : null,
    verifiedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };

  if (userId) {
    paymentData.userId = userId;
    try {
      const userDoc = await adminDb.collection("users").doc(userId).get();
      if (userDoc.exists) paymentData.userEmail = userDoc.data()?.email || "";
    } catch {}
  }

  const existingDoc = await paymentRef.get();
  if (existingDoc.exists) {
    // Preserve original orderId for reference
    paymentData.orderId = existingDoc.data()?.orderId || paymentDocId;
    await paymentRef.update(paymentData);
  } else {
    await paymentRef.set({
      ...paymentData,
      orderId: paymentDocId,
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
      userUpdate.activeSubscriptionId = paymentDocId;
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
 * In-app purchases have no expiry but still need acknowledgement within 3 days
 * (Google auto-refunds otherwise). VIP grant is NOT given for one-time purchases
 * unless the app explicitly maps specific SKUs to lifetime VIP via a separate rule.
 */
async function handleOneTimeProductNotification(notification: any, raw: any) {
  const { purchaseToken, sku } = notification;
  if (!purchaseToken || !sku) return;

  // Stable doc ID based on purchaseToken
  const paymentDocId = createHash("sha256")
    .update(purchaseToken)
    .digest("hex")
    .slice(0, 40);
  const status = "active"; // one-time products are always active after purchase

  const paymentRef = adminDb.collection("payments").doc(paymentDocId);
  await paymentRef.set(
    {
      purchaseToken,
      productId: sku,
      purchaseType: "inapp",
      status,
      amount: 0,
      currency: "VND",
      verifiedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      rawNotification: raw,
    },
    { merge: true },
  );

  // Acknowledge in-app purchase (required within 3 days, prevents auto-refund)
  try {
    await acknowledgeProduct(sku, purchaseToken);
  } catch (err) {
    console.warn(
      "[GooglePlay Webhook] In-app acknowledge failed (may already be acknowledged):",
      err,
    );
  }
}
