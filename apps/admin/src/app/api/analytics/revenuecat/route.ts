import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import type {
  RevenueCatSubscriber,
  RevenueCatAnalytics,
} from "@/types/revenuecat";

const REVENUECAT_API_KEY = process.env.REVENUECAT_API_KEY;
const REVENUECAT_APP_ID = process.env.REVENUECAT_APP_ID; // optional — if not set, returns data for all apps

/**
 * GET /api/analytics/revenuecat
 *
 * Returns RevenueCat subscriber analytics pulled from the RevenueCat REST API v1.
 * Requires REVENUECAT_API_KEY env var.
 *
 * RevenueCat API docs: https://www.revenuecat.com/docs/api
 *
 * Response shape: RevenueCatAnalytics
 */
export async function GET(req: Request) {
  try {
    await requireAdmin(req);
  } catch (authError: any) {
    return NextResponse.json(
      { error: authError.message },
      { status: authError.status || 401 },
    );
  }

  if (!REVENUECAT_API_KEY) {
    return NextResponse.json(
      {
        error:
          "RevenueCat API key not configured. Set REVENUECAT_API_KEY in your environment.",
        code: "REVENUECAT_NOT_CONFIGURED",
      },
      { status: 503 },
    );
  }

  try {
    const now = Date.now();
    const analytics = await fetchRevenueCatAnalytics(
      REVENUECAT_API_KEY,
      REVENUECAT_APP_ID,
    );

    return NextResponse.json({
      ...analytics,
      generatedAt: new Date(now).toISOString(),
    });
  } catch (error: any) {
    console.error("[RevenueCat Analytics] Error:", error);
    return NextResponse.json(
      { error: error.message || "Failed to fetch RevenueCat analytics." },
      { status: 500 },
    );
  }
}

async function fetchRevenueCatAnalytics(
  apiKey: string,
  appId?: string,
): Promise<Omit<RevenueCatAnalytics, "generatedAt">> {
  // RevenueCat's /subscribers endpoint returns all active subscribers with entitlements.
  // We paginate through them to compute real-time stats.
  // For large apps (>10k subscribers) this should be replaced with RevenueCat's
  // /analytics/metrics endpoint or a nightly BigQuery/Redshift export.
  //
  // Docs: GET /v1/subscribers
  //   - entitlement: filter by entitlement ID (e.g. "vip")
  //   - limit: max subscribers per page (default 50, max 200)
  //   - cursor: pagination cursor from previous response

  const baseUrl = "https://api.revenuecat.com/v1/subscribers";
  const params = new URLSearchParams({
    limit: "200",
    // Only fetch subscribers who have the VIP entitlement
    entitlement: "vip",
  });
  if (appId) params.set("app_user_id", appId);

  let allSubscribers: RevenueCatSubscriber[] = [];
  let cursor: string | null = null;
  const MAX_PAGES = 20; // safety cap: 20 pages × 200 = 4000 subscribers max

  for (let page = 0; page < MAX_PAGES; page++) {
    if (cursor) params.set("cursor", cursor);

    const res = await fetch(`${baseUrl}?${params}`, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      cache: "no-store",
    });

    if (!res.ok) {
      const body = await res.text();
      throw new Error(`RevenueCat API ${res.status}: ${body}`);
    }

    const json = (await res.json()) as {
      subscribers: RevenueCatSubscriber[];
      next_cursor?: string;
      [key: string]: any;
    };

    allSubscribers = allSubscribers.concat(json.subscribers || []);
    cursor = json.next_cursor || null;

    if (!cursor) break;
  }

  // ── Aggregate ───────────────────────────────────────────────────────────────

  let activeEntitlements = 0;
  let trialCount = 0;
  let cancelledCount = 0;
  let gracePeriodCount = 0;
  const now = Date.now();
  const productRevenue: Record<
    string,
    { count: number; revenueCents: number }
  > = {};
  const currencyBreakdown: Record<string, number> = {};
  let totalMrrCents = 0;
  let totalArrCents = 0;

  for (const sub of allSubscribers) {
    if (!sub.subscriptions || sub.subscriptions.length === 0) continue;

    // Check each subscription for the "vip" entitlement
    for (const subInfo of sub.subscriptions) {
      // Skip if this subscription doesn't have vip entitlement
      if (!sub.entitlement_ids?.includes("vip")) continue;

      const expiry = subInfo.auto_expiry_date_ms;
      const isActive = expiry == null || expiry > now;
      const isTrial =
        subInfo.period_type === "trial" || subInfo.is_trial_conversion;
      const isCancelled = !subInfo.auto_renewing;
      const isGrace = !!subInfo.grace_period_expires_date_ms;

      if (isActive) {
        activeEntitlements++;
        if (isTrial) trialCount++;

        // Estimate MRR: assume monthly price of 99,000 VND for VIP.
        // In production, fetch product prices from RevenueCat /products endpoint.
        // Here we use a heuristic: annual subs = ARR/12 for display only.
        totalMrrCents += 99000; // placeholder — replace with real price from /products
      }

      if (isCancelled && !isGrace) cancelledCount++;
      if (isGrace) gracePeriodCount++;

      // Track by product
      const pid = subInfo.product_identifier;
      if (!productRevenue[pid])
        productRevenue[pid] = { count: 0, revenueCents: 0 };
      productRevenue[pid].count++;
      if (isActive) productRevenue[pid].revenueCents += 99000;
    }
  }

  totalArrCents = totalMrrCents * 12;

  const topProducts = Object.entries(productRevenue)
    .map(([productId, data]) => ({
      productId,
      count: data.count,
      revenueCents: data.revenueCents,
    }))
    .sort((a, b) => b.revenueCents - a.revenueCents)
    .slice(0, 5);

  return {
    activeEntitlements,
    mrrCents: totalMrrCents,
    mrrFormatted: formatVND(totalMrrCents / 100),
    annualRecurringRevenueCents: totalArrCents,
    arrFormatted: formatVND(totalArrCents / 100),
    subscribersCount: allSubscribers.length,
    trialCount,
    cancelledCount,
    gracePeriodCount,
    topProducts,
    currencyBreakdown,
  };
}

const revenuecatVndFormatter = new Intl.NumberFormat("vi-VN", {
  style: "currency",
  currency: "VND",
  maximumFractionDigits: 0,
});

function formatVND(amount: number): string {
  return revenuecatVndFormatter.format(amount);
}
