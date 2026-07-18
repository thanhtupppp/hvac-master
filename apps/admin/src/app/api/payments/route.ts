import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { adminDb } from "@/lib/firebase-admin";
import { z } from "zod";
import { FieldValue } from "firebase-admin/firestore";
import { verifySubscription, verifyProduct, mapSubscriptionStatus } from "@/lib/google-play";

const syncSchema = z.object({
  purchaseToken: z.string().min(10),
  productId: z.string().min(3),
  purchaseType: z.enum(["subscription", "inapp"]).default("subscription"),
  userId: z.string().optional(),
  userEmail: z.string().email().optional(),
});

const patchSchema = z.object({
  id: z.string().min(1),
  status: z.enum(["pending", "active", "expired", "cancelled", "refunded"]),
  note: z.string().max(500).optional(),
});

/**
 * GET /api/payments — List all payments (Admin only)
 */
export async function GET(req: Request) {
  try {
    await requireAdmin(req);
  } catch (authError: any) {
    return NextResponse.json({ error: authError.message }, { status: authError.status || 401 });
  }

  try {
    const url = new URL(req.url);
    const filter = url.searchParams.get("filter") || "all";
    const search = url.searchParams.get("search") || "";
    const limitParam = parseInt(url.searchParams.get("limit") || "100", 10);
    const limit = Math.min(limitParam, 200);

    let query: FirebaseFirestore.Query = adminDb.collection("payments").orderBy("purchaseTime", "desc").limit(limit);

    if (filter !== "all") {
      query = adminDb.collection("payments")
        .where("status", "==", filter)
        .orderBy("purchaseTime", "desc")
        .limit(limit);
    }

    const snapshot = await query.get();
    let payments = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    if (search) {
      const q = search.toLowerCase();
      payments = payments.filter((p: any) =>
        p.userEmail?.toLowerCase().includes(q) ||
        p.orderId?.toLowerCase().includes(q) ||
        p.productId?.toLowerCase().includes(q)
      );
    }

    // Stats
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfWeek = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    const allActiveSnap = await adminDb.collection("payments").where("status", "==", "active").get();
    const activeSubscribers = allActiveSnap.size;

    let revenueThisMonth = 0;
    let newThisWeek = 0;
    allActiveSnap.forEach((doc) => {
      const d = doc.data();
      const pt = d.purchaseTime?.toDate?.() || new Date(0);
      if (pt >= startOfMonth) revenueThisMonth += d.amount || 0;
      if (pt >= startOfWeek) newThisWeek++;
    });

    const pendingSnap = await adminDb.collection("payments").where("status", "==", "pending").get();

    const stats = { activeSubscribers, revenueThisMonth, newThisWeek, pendingCount: pendingSnap.size };

    return NextResponse.json({ payments, total: payments.length, stats });
  } catch (error) {
    console.error("Error listing payments:", error);
    return NextResponse.json({ error: "Failed to fetch payments." }, { status: 500 });
  }
}

/**
 * POST /api/payments — Manually sync/verify a purchase token
 */
export async function POST(req: Request) {
  try {
    await requireAdmin(req);
  } catch (authError: any) {
    return NextResponse.json({ error: authError.message }, { status: authError.status || 401 });
  }

  try {
    const body = await req.json().catch(() => null);
    const parsed = syncSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: "Dữ liệu không hợp lệ.", details: parsed.error.format() }, { status: 400 });
    }

    const { purchaseToken, productId, purchaseType, userId, userEmail } = parsed.data;

    let orderId: string;
    let status: string;
    let expiryTime: any = null;

    if (purchaseType === "subscription") {
      const sub = await verifySubscription(productId, purchaseToken);
      orderId = sub.latestOrderId || purchaseToken.slice(0, 40);
      status = mapSubscriptionStatus(sub.subscriptionState);
      const expiryMillis = sub.lineItems?.[0]?.expiryTime
        ? new Date(sub.lineItems[0].expiryTime).getTime()
        : null;
      if (expiryMillis) {
        const { Timestamp } = await import("firebase-admin/firestore");
        expiryTime = Timestamp.fromMillis(expiryMillis);
      }
    } else {
      const product = await verifyProduct(productId, purchaseToken);
      orderId = product.orderId || purchaseToken.slice(0, 40);
      status = product.purchaseState === 0 ? "active" : "pending";
    }

    const paymentRef = adminDb.collection("payments").doc(orderId);
    await paymentRef.set({
      orderId,
      purchaseToken,
      productId,
      purchaseType,
      status,
      userId: userId || null,
      userEmail: userEmail || null,
      amount: 0,
      currency: "VND",
      expiryTime,
      purchaseTime: FieldValue.serverTimestamp(),
      verifiedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    // If userId known and active → grant VIP
    if (userId && status === "active" && expiryTime) {
      await adminDb.collection("users").doc(userId).set({
        isPremium: true,
        premiumExpiry: expiryTime,
        activeSubscriptionId: orderId,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    return NextResponse.json({ success: true, orderId, status });
  } catch (error: any) {
    console.error("Error syncing payment:", error);
    return NextResponse.json({ error: error.message || "Failed to sync payment." }, { status: 500 });
  }
}

/**
 * PATCH /api/payments — Manually override payment status
 */
export async function PATCH(req: Request) {
  try {
    await requireAdmin(req);
  } catch (authError: any) {
    return NextResponse.json({ error: authError.message }, { status: authError.status || 401 });
  }

  try {
    const body = await req.json().catch(() => null);
    const parsed = patchSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: "Dữ liệu không hợp lệ.", details: parsed.error.format() }, { status: 400 });
    }

    const { id, status, note } = parsed.data;
    const update: Record<string, any> = { status, updatedAt: FieldValue.serverTimestamp() };
    if (note) update.note = note;

    await adminDb.collection("payments").doc(id).update(update);

    // If refunded/cancelled → revoke VIP if applicable
    if (status === "refunded" || status === "cancelled") {
      const payDoc = await adminDb.collection("payments").doc(id).get();
      const userId = payDoc.data()?.userId;
      if (userId) {
        await adminDb.collection("users").doc(userId).set({
          isPremium: false,
          premiumExpiry: null,
          activeSubscriptionId: null,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Error updating payment:", error);
    return NextResponse.json({ error: "Failed to update payment." }, { status: 500 });
  }
}
