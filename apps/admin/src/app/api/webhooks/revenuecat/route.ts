import { NextResponse } from "next/server";
import { adminDb } from "@/lib/firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { createHmac, timingSafeEqual, createHash } from "crypto";

/**
 * POST /api/webhooks/revenuecat
 *
 * RevenueCat sends webhook events for all store purchases (Google Play, Apple, etc.).
 * This replaces the Google Play webhook as the single source of truth for entitlements.
 *
 * RevenueCat docs: https://www.revenuecat.com/docs/webhooks
 *
 * Event flow:
 *   INITIAL_PURCHASE / RENEWAL → grant VIP
 *   CANCELLATION / EXPIRATION / BILLING_ISSUE → revoke VIP
 *   UNCANCELLATION → re-grant VIP
 *   TRIAL_CONVERTED → treat as INITIAL_PURCHASE
 */
export async function POST(req: Request) {
  // 1. Verify RevenueCat webhook signature
  const webhookSecret = process.env.REVENUECAT_WEBHOOK_SECRET;
  if (!webhookSecret) {
    console.error(
      "[RevenueCat Webhook] REVENUECAT_WEBHOOK_SECRET not configured.",
    );
    return NextResponse.json(
      { error: "Webhook not configured." },
      { status: 503 },
    );
  }

  const signature = req.headers.get("RC_WEBHOOK_SIGNATURE");
  if (!signature) {
    console.warn("[RevenueCat Webhook] Missing RC_WEBHOOK_SIGNATURE header.");
    return NextResponse.json({ error: "Missing signature." }, { status: 401 });
  }

  let rawBody: string;
  try {
    rawBody = await req.text();
  } catch {
    return NextResponse.json({ error: "Invalid body." }, { status: 400 });
  }

  // Compute expected HMAC-SHA256 of raw body
  const expectedSig = createHmac("sha256", webhookSecret)
    .update(rawBody)
    .digest("hex");

  // Timing-safe comparison to prevent timing attacks
  try {
    const receivedBuf = Buffer.from(signature, "hex");
    const expectedBuf = Buffer.from(expectedSig, "hex");
    if (
      receivedBuf.length !== expectedBuf.length ||
      !timingSafeEqual(receivedBuf, expectedBuf)
    ) {
      console.warn("[RevenueCat Webhook] Invalid webhook signature.");
      return NextResponse.json(
        { error: "Invalid signature." },
        { status: 401 },
      );
    }
  } catch {
    console.warn("[RevenueCat Webhook] Signature comparison failed.");
    return NextResponse.json(
      { error: "Invalid signature format." },
      { status: 401 },
    );
  }

  // 2. Parse payload
  let payload: RevenueCatWebhookPayload;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return NextResponse.json({ error: "Invalid JSON." }, { status: 400 });
  }

  const event = payload.event;
  if (!event) {
    console.warn("[RevenueCat Webhook] No event in payload.");
    return NextResponse.json({ error: "No event." }, { status: 200 });
  }

  const {
    event_id,
    event_type,
    app_user_id: userId,
    product_id: productId,
    entitlement_id: entitlementId,
    entitlement_ids: entitlementIds = [],
    store,
    expiration_at_ms: expirationAtMs,
    purchase_at_ms: purchaseAtMs,
    period_type: periodType,
    is_trial_conversion: isTrialConversion,
    price_in_app_currency: priceInAppCurrency,
    iso_currency_code: isoCurrencyCode,
    transaction_id: transactionId,
  } = event;

  console.log(
    `[RevenueCat Webhook] event_id=${event_id} type=${event_type} user=${userId} product=${productId}`,
  );

  // Only process VIP entitlement events — ignore other entitlement_ids
  const vipEntitlementId =
    entitlementId ||
    entitlementIds.find(
      (id) =>
        id.toLowerCase().includes("vip") ||
        id.toLowerCase().includes("premium"),
    ) ||
    entitlementIds[0];

  if (!userId || !vipEntitlementId) {
    console.log(
      "[RevenueCat Webhook] Skipping — no userId or VIP entitlement.",
    );
    return NextResponse.json(
      { ok: true, reason: "no_vip_entitlement" },
      { status: 200 },
    );
  }

  // 3. Derive payment doc ID (stable per purchaseToken/transactionId)
  const paymentDocId = transactionId
    ? createHash("sha256").update(transactionId).digest("hex").slice(0, 40)
    : event_id;

  // 4. Determine VIP status from event type
  const isGranting = isVipGrantingEvent(event_type, isTrialConversion);
  const isRevoking = isVipRevokingEvent(event_type);

  // 5. Upsert payment record
  const expiryTime = expirationAtMs
    ? Timestamp.fromMillis(expirationAtMs)
    : null;
  const purchaseTime = purchaseAtMs
    ? Timestamp.fromMillis(purchaseAtMs)
    : FieldValue.serverTimestamp();
  try {
    const paymentRef = adminDb.collection("payments").doc(paymentDocId);

    await paymentRef.set(
      {
        revenuecatEventId: event_id,
        revenuecatTransactionId: transactionId,
        purchaseToken: transactionId,
        productId,
        purchaseType: store === "GOOGLE_PLAY" ? "subscription" : "inapp",
        entitlementId: vipEntitlementId,
        store,
        status: isGranting ? "active" : isRevoking ? "expired" : "pending",
        autoRenewing: isRevoking ? false : true,
        expiryTime,
        purchaseTime,
        amount: priceInAppCurrency ?? 0,
        currency: isoCurrencyCode ?? "VND",
        periodType: periodType || "normal",
        isTrialConversion: isTrialConversion || false,
        revenuecatEventType: event_type,
        verifiedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    // Look up user email if available
    try {
      const userDoc = await adminDb.collection("users").doc(userId).get();
      if (userDoc.exists) {
        await paymentRef.update({
          userId,
          userEmail: userDoc.data()?.email || "",
        });
      }
    } catch {}
  } catch (err) {
    console.error("[RevenueCat Webhook] Failed to write payment doc:", err);
  }

  // 6. Update user VIP entitlement
  if (isGranting) {
    await grantVip(userId, paymentDocId, expiryTime);
  } else if (isRevoking) {
    await revokeVip(userId);
  }

  return NextResponse.json({ ok: true, event_id }, { status: 200 });
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function isVipGrantingEvent(
  eventType: string,
  isTrialConversion?: boolean,
): boolean {
  const type = (eventType || "").toUpperCase();
  return (
    type === "INITIAL_PURCHASE" ||
    type === "RENEWAL" ||
    type === "UNCANCELLATION" ||
    type === "TRIAL_CONVERTED" ||
    (type === "TRIAL_START" && !!isTrialConversion)
  );
}

function isVipRevokingEvent(eventType: string): boolean {
  const type = (eventType || "").toUpperCase();
  return (
    type === "CANCELLATION" || type === "EXPIRATION" || type === "BILLING_ISSUE"
  );
}

async function grantVip(
  userId: string,
  activeSubscriptionId: string,
  expiryTime: Timestamp | null,
): Promise<void> {
  const userUpdate: Record<string, any> = {
    isPremium: true,
    activeSubscriptionId,
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (expiryTime) {
    userUpdate.premiumExpiry = expiryTime;
  }
  await adminDb
    .collection("users")
    .doc(userId)
    .set(userUpdate, { merge: true });
  console.log(`[RevenueCat Webhook] Granted VIP to user ${userId}`);
}

async function revokeVip(userId: string): Promise<void> {
  await adminDb.collection("users").doc(userId).set(
    {
      isPremium: false,
      premiumExpiry: null,
      activeSubscriptionId: null,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  console.log(`[RevenueCat Webhook] Revoked VIP from user ${userId}`);
}

// ─── Types ─────────────────────────────────────────────────────────────────

interface RevenueCatWebhookPayload {
  event: {
    event_id: string;
    event_type: string;
    app_user_id: string;
    product_id: string;
    entitlement_id?: string;
    entitlement_ids?: string[];
    store: string;
    expiration_at_ms?: number;
    purchase_at_ms?: number;
    period_type?: string;
    is_trial_conversion?: boolean;
    price_in_app_currency?: number;
    iso_currency_code?: string;
    transaction_id?: string;
  };
}
