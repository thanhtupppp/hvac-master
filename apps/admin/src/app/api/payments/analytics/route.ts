import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { adminDb } from "@/lib/firebase-admin";

/**
 * GET /api/payments/analytics
 *
 * Returns aggregated payment analytics:
 *   - MRR (Monthly Recurring Revenue)
 *   - Revenue by month (last 12 months)
 *   - Active subscribers breakdown
 *   - Churn rate
 *   - Top products
 *
 * Uses Firestore aggregation queries + in-memory aggregation
 * (suitable for up to ~10k payment docs; beyond that use
 *  Cloud Firestore aggregation pipelines or BigQuery).
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

  try {
    const now = new Date();
    const twelveMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 11, 1);

    // ── 1. Active subscribers (current MRR) ───────────────────────────────
    const activeSnap = await adminDb
      .collection("payments")
      .where("status", "==", "active")
      .where("purchaseType", "==", "subscription")
      .get();

    const activePayments = activeSnap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .filter((p: any) => {
        // Exclude expired subscriptions (webhook might have missed them)
        const expiry = p.expiryTime?.toDate?.() || null;
        return !expiry || expiry > now;
      });

    const mrr = activePayments.reduce(
      (sum: number, p: any) => sum + (p.amount || 0),
      0,
    );

    // ── 2. Revenue by month (last 12 months) ──────────────────────────────
    const revenueSnap = await adminDb
      .collection("payments")
      .where("purchaseTime", ">=", twelveMonthsAgo)
      .get();

    const monthlyRevenue: Record<string, number> = {};
    for (let i = 0; i < 12; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
      monthlyRevenue[key] = 0;
    }

    revenueSnap.docs.forEach((doc) => {
      const d = doc.data();
      const pt = d.purchaseTime?.toDate?.();
      if (!pt) return;
      const key = `${pt.getFullYear()}-${String(pt.getMonth() + 1).padStart(2, "0")}`;
      if (key in monthlyRevenue) {
        // Count active/paid payments only
        if (d.status === "active" || d.status === "expired") {
          monthlyRevenue[key] += d.amount || 0;
        }
      }
    });

    const revenueByMonth = (
      Object.entries(monthlyRevenue) as [string, number][]
    )
      .map(([month, revenue]) => ({ month, revenue }))
      .sort((a, b) => a.month.localeCompare(b.month));

    // ── 3. Subscriber counts ─────────────────────────────────────────────
    const totalActive = activePayments.length;

    // Aggregation counts — only need .size, not full docs
    const [vipCountSnap, totalUsersSnap] = await Promise.all([
      adminDb.collection("users").where("isPremium", "==", true).count().get(),
      adminDb.collection("users").count().get(),
    ]);
    const vipCount = vipCountSnap.data().count;
    const totalUsers = totalUsersSnap.data().count;

    // ── 4. Churn rate (monthly) ─────────────────────────────────────────
    // Churn = subscriptions that expired this month / active at start of month
    const startOfThisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);

    const [
      expiredThisMonthSnap,
      cancelledThisMonthSnap,
      newSubsThisMonthSnap,
      newSubsLastMonthSnap,
    ] = await Promise.all([
      adminDb
        .collection("payments")
        .where("status", "==", "expired")
        .where("expiryTime", ">=", startOfThisMonth)
        .count()
        .get(),
      adminDb
        .collection("payments")
        .where("status", "==", "cancelled")
        .where("updatedAt", ">=", startOfThisMonth)
        .count()
        .get(),
      adminDb
        .collection("payments")
        .where("purchaseTime", ">=", startOfThisMonth)
        .count()
        .get(),
      adminDb
        .collection("payments")
        .where("purchaseTime", ">=", startOfLastMonth)
        .where("purchaseTime", "<", startOfThisMonth)
        .count()
        .get(),
    ]);

    const churnedThisMonth =
      expiredThisMonthSnap.data().count + cancelledThisMonthSnap.data().count;

    // Active at start of last month (approximation: active payments - new this month)
    const activeAtStartOfMonth = Math.max(
      1,
      totalActive - newSubsThisMonthSnap.data().count,
    );
    const churnRate =
      activeAtStartOfMonth > 0
        ? Math.round((churnedThisMonth / activeAtStartOfMonth) * 1000) / 10
        : 0;

    // ── 5. New subscribers this month ────────────────────────────────────
    const newSubsThisMonth = newSubsThisMonthSnap.data().count;
    const newSubsLastMonth = newSubsLastMonthSnap.data().count;

    // ── 6. Top products by revenue ───────────────────────────────────────
    const productRevenue: Record<string, { revenue: number; count: number }> =
      {};
    revenueSnap.docs.forEach((doc) => {
      const d = doc.data();
      const pid = d.productId || "unknown";
      if (!productRevenue[pid]) productRevenue[pid] = { revenue: 0, count: 0 };
      if (d.status === "active" || d.status === "expired") {
        productRevenue[pid].revenue += d.amount || 0;
        productRevenue[pid].count += 1;
      }
    });

    const topProducts = (
      Object.entries(productRevenue) as [
        string,
        { revenue: number; count: number },
      ][]
    )
      .map(([productId, data]) => ({ productId, ...data }))
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 5);

    // ── 7. Subscription type breakdown ───────────────────────────────────
    // Reuse activeSnap from section 1 — same predicate (active + subscription).
    const activeSubscriptions = activeSnap.size;
    const activeInApps = (
      await adminDb
        .collection("payments")
        .where("purchaseType", "==", "inapp")
        .where("status", "==", "active")
        .count()
        .get()
    ).data().count;

    // ── 8. Refund rate ───────────────────────────────────────────────────
    const refundedCount = (
      await adminDb
        .collection("payments")
        .where("status", "==", "refunded")
        .count()
        .get()
    ).data().count;
    const totalPayments = revenueSnap.size;
    const refundRate =
      totalPayments > 0
        ? Math.round((refundedCount / totalPayments) * 1000) / 10
        : 0;

    const analytics = {
      mrr, // VND
      mrrFormatted: formatVND(mrr),
      activeSubscriptions,
      activeInApps,
      totalActive,
      vipCount,
      totalUsers,
      vipRate:
        totalUsers > 0 ? Math.round((vipCount / totalUsers) * 1000) / 10 : 0,
      newSubsThisMonth,
      newSubsLastMonth,
      churnedThisMonth,
      churnRate, // percentage
      refundRate, // percentage
      revenueByMonth,
      topProducts,
      generatedAt: now.toISOString(),
    };

    return NextResponse.json(analytics);
  } catch (error) {
    console.error("Error generating analytics:", error);
    return NextResponse.json(
      { error: "Failed to generate analytics." },
      { status: 500 },
    );
  }
}

function formatVND(amount: number): string {
  return new Intl.NumberFormat("vi-VN", {
    style: "currency",
    currency: "VND",
    maximumFractionDigits: 0,
  }).format(amount);
}
