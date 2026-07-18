import { google } from "googleapis";

const PACKAGE_NAME = process.env.GOOGLE_PLAY_PACKAGE_NAME || "";

function getAndroidPublisher() {
  const keyRaw = process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_KEY;
  if (!keyRaw) throw new Error("GOOGLE_PLAY_SERVICE_ACCOUNT_KEY is not configured.");

  const key = typeof keyRaw === "string" ? JSON.parse(keyRaw) : keyRaw;

  const auth = new google.auth.GoogleAuth({
    credentials: key,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });

  return google.androidpublisher({ version: "v3", auth });
}

/**
 * Verify a Google Play subscription purchase.
 * Returns the subscription object or throws if invalid.
 */
export async function verifySubscription(subscriptionId: string, purchaseToken: string) {
  const androidpublisher = getAndroidPublisher();
  const res = await androidpublisher.purchases.subscriptionsv2.get({
    packageName: PACKAGE_NAME,
    token: purchaseToken,
  });
  return res.data;
}

/**
 * Verify a Google Play one-time in-app product purchase.
 */
export async function verifyProduct(productId: string, purchaseToken: string) {
  const androidpublisher = getAndroidPublisher();
  const res = await androidpublisher.purchases.products.get({
    packageName: PACKAGE_NAME,
    productId,
    token: purchaseToken,
  });
  return res.data;
}

/**
 * Acknowledge a subscription purchase (required within 3 days).
 */
export async function acknowledgeSubscription(subscriptionId: string, purchaseToken: string) {
  const androidpublisher = getAndroidPublisher();
  await androidpublisher.purchases.subscriptions.acknowledge({
    packageName: PACKAGE_NAME,
    subscriptionId,
    token: purchaseToken,
    requestBody: {},
  });
}

/**
 * Parse priceMicros to VND integer.
 * Google Play stores prices in micros (1 VND = 1_000_000 micros).
 */
export function microsToCurrency(priceMicros: string | null | undefined): number {
  if (!priceMicros) return 0;
  return Math.round(parseInt(priceMicros, 10) / 1_000_000);
}

/**
 * Map Google Play subscription state to internal status.
 * subscriptionState: ACTIVE | CANCELED | IN_GRACE_PERIOD | ON_HOLD | PAUSED | EXPIRED
 */
export function mapSubscriptionStatus(
  state: string | null | undefined
): "active" | "cancelled" | "expired" | "pending" {
  switch (state) {
    case "SUBSCRIPTION_STATE_ACTIVE":
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
      return "active";
    case "SUBSCRIPTION_STATE_CANCELED":
    case "SUBSCRIPTION_STATE_ON_HOLD":
    case "SUBSCRIPTION_STATE_PAUSED":
      return "cancelled";
    case "SUBSCRIPTION_STATE_EXPIRED":
      return "expired";
    default:
      return "pending";
  }
}
