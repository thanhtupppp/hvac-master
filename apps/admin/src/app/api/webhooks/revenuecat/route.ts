import { NextResponse } from "next/server";
import { adminDb } from "@/lib/firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { timingSafeEqual } from "crypto";

/**
 * POST /api/webhooks/revenuecat
 *
 * RevenueCat sends webhook events for all store purchases (Google Play, Apple, etc.).
 * RevenueCat dashboard → Integration → Webhooks: set the webhook URL and a custom
 * "Webhook Secret" (a shared secret you define). RevenueCat sends this secret in the
 * HTTP `Authorization` header as a bearer token: `Authorization: Bearer <secret>`.
 *
 * This replaces the Google Play webhook for user entitlement management.
 * The Google Play webhook is kept for product acknowledgement only (which must be
 * done per-platform to prevent auto-refunds).
 *
 * RevenueCat event docs: https://www.revenuecat.com/docs/webhooks
 */
export async function POST(req: Request) {
  // 1. Verify Authorization header (simple shared-secret bearer token)
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

  const authHeader = req.headers.get("authorization");
  if (!authHeader) {
    console.warn("[RevenueCat Webhook] Missing Authorization header.");
    return NextResponse.json({ error: "Missing auth." }, { status: 401 });
  }

  const receivedToken = authHeader.startsWith("Bearer ")
    ? authHeader.slice(7)
    : authHeader;

  // Timing-safe comparison to prevent timing attacks
  const encoder = new TextEncoder();
  try {
    const receivedBuf = encoder.encode(receivedToken);
    const expectedBuf = encoder.encode(webhookSecret);
    if (
      receivedBuf.length !== expectedBuf.length ||
      !timingSafeEqual(receivedBuf, expectedBuf)
    ) {
      console.warn("[RevenueCat Webhook] Invalid Authorization token.");
      return NextResponse.json({ error: "Unauthorized." }, { status: 401 });
    }
  } catch {
    console.warn("[RevenueCat Webhook] Authorization comparison failed.");
    return NextResponse.json({ error: "Auth error." }, { status: 401 });
  }

  // 2. Parse payload
  let rawBody: string;
  try {
    rawBody = await req.text();
  } catch {
    return NextResponse.json({ error: "Invalid body." }, { status: 400 });
  }

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
    price_in_purchased_currency: priceInPurchasedCurrency,
    iso_currency_code: isoCurrencyCode,
    transaction_id: transactionId,
    original_transaction_id: originalTransactionId,
    auto_renewing: autoRenewing,
  } = event;

  console.log(
    `[RevenueCat Webhook] event_id=${event_id} type=${event_type} user=${userId} product=${productId}`,
  );

  // Only process VIP entitlement events
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

  // 3. Derive a stable payment doc ID.
  // Use original_transaction_id when available — it stays the same across all
  // renewals of the same subscription. Fall back to event_id.
  // We deliberately do NOT use transaction_id as it changes every billing cycle
  // (same problem as latestOrderId in the old Google Play webhook).
  const stableId = originalTransactionId || event_id;
  const paymentDocId = stableId;

  // 4. Determine VIP status from event type
  const isGranting = isVipGrantingEvent(event_type, isTrialConversion);
  const isDefinitelyRevoking = isDefinitelyRevokingEvent(event_type);

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
        revenuecatOriginalTransactionId: originalTransactionId || null,
        purchaseToken: originalTransactionId || transactionId || event_id,
        productId,
        purchaseType: store === "GOOGLE_PLAY" ? "subscription" : "inapp",
        entitlementId: vipEntitlementId,
        store,
        status: isGranting
          ? "active"
          : isDefinitelyRevoking
            ? "expired"
            : "pending",
        // autoRenewing: false only when user has cancelled (not for grace-period
        // BILLING_ISSUE which still has time left).
        autoRenewing: autoRenewing ?? null,
        expiryTime,
        purchaseTime,
        // RevenueCat sends price_in_purchased_currency (amount in the currency the
        // user was charged). price_in_app_currency is the USD base price — wrong.
        amount: priceInPurchasedCurrency ?? 0,
        currency: isoCurrencyCode ?? null,
        periodType: periodType || "normal",
        isTrialConversion: isTrialConversion || false,
        revenuecatEventType: event_type,
        verifiedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    // Backfill user email if available
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
  } else if (isDefinitelyRevoking) {
    await revokeVip(userId);
  }
  // CANCELLATION and BILLING_ISSUE: do NOT revoke here.
  // CANCELLATION means auto-renew is OFF but user still has access until period end.
  // BILLING_ISSUE means payment failed — RevenueCat retries for ~3-7 days.
  // Revoke only on EXPIRATION.

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

/** Events that definitively end the subscription — revoke VIP immediately. */
function isDefinitelyRevokingEvent(eventType: string): boolean {
  const type = (eventType || "").toUpperCase();
  return type === "EXPIRATION";
  // NOTE: CANCELLATION means "user turned off auto-renew" — they still have
  // access until period end. BILLING_ISSUE has a grace period. Neither should
  // revoke VIP here. RevenueCat will send EXPIRATION when access truly ends.
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
    price_in_purchased_currency?: number;
    iso_currency_code?: string;
    transaction_id?: string;
    original_transaction_id?: string;
    auto_renewing?: boolean;
    [key: string]: any;
  };
}
