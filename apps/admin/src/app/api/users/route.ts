import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { adminDb } from "@/lib/firebase-admin";
import { z } from "zod";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

const updateUserSchema = z.object({
  uid: z.string().min(1),
  isPremium: z.boolean().optional(),
  status: z.enum(["active", "disabled"]).optional(),
  premiumDays: z.number().int().min(1).max(3650).optional(), // extend premium by N days
});

/**
 * GET /api/users — List all users (Admin only)
 */
export async function GET(req: Request) {
  try {
    await requireAdmin(req);
  } catch (authError: any) {
    return NextResponse.json({ error: authError.message }, { status: authError.status || 401 });
  }

  try {
    const url = new URL(req.url);
    const filter = url.searchParams.get("filter") || "all"; // all | vip | free | disabled
    const search = url.searchParams.get("search") || "";
    const limitParam = parseInt(url.searchParams.get("limit") || "100", 10);
    const limit = Math.min(limitParam, 200);

    let query: FirebaseFirestore.Query = adminDb.collection("users").orderBy("createdAt", "desc").limit(limit);

    if (filter === "vip") {
      query = adminDb.collection("users").where("isPremium", "==", true).orderBy("createdAt", "desc").limit(limit);
    } else if (filter === "free") {
      query = adminDb.collection("users").where("isPremium", "==", false).orderBy("createdAt", "desc").limit(limit);
    } else if (filter === "disabled") {
      query = adminDb.collection("users").where("status", "==", "disabled").orderBy("createdAt", "desc").limit(limit);
    }

    const snapshot = await query.get();
    let users = snapshot.docs.map((doc) => ({
      uid: doc.id,
      ...doc.data(),
    }));

    // Client-side search filter (Firestore doesn't support full-text search)
    if (search) {
      const q = search.toLowerCase();
      users = users.filter((u: any) =>
        u.email?.toLowerCase().includes(q) ||
        u.displayName?.toLowerCase().includes(q)
      );
    }

    return NextResponse.json({ users, total: users.length });
  } catch (error) {
    console.error("Error listing users:", error);
    return NextResponse.json({ error: "Failed to fetch users." }, { status: 500 });
  }
}

/**
 * PATCH /api/users — Update user VIP status or account status
 */
export async function PATCH(req: Request) {
  try {
    await requireAdmin(req);
  } catch (authError: any) {
    return NextResponse.json({ error: authError.message }, { status: authError.status || 401 });
  }

  try {
    const body = await req.json().catch(() => null);
    const parsed = updateUserSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: "Dữ liệu không hợp lệ.", details: parsed.error.format() }, { status: 400 });
    }

    const { uid, isPremium, status, premiumDays } = parsed.data;
    const update: Record<string, any> = { updatedAt: FieldValue.serverTimestamp() };

    if (typeof isPremium === "boolean") update.isPremium = isPremium;
    if (status) update.status = status;

    if (premiumDays !== undefined) {
      const expiry = new Date();
      expiry.setDate(expiry.getDate() + premiumDays);
      update.premiumExpiry = Timestamp.fromDate(expiry);
      update.isPremium = true;
    }

    if (!isPremium && premiumDays === undefined) {
      update.premiumExpiry = null;
      update.activeSubscriptionId = null;
    }

    await adminDb.collection("users").doc(uid).set(update, { merge: true });

    return NextResponse.json({ success: true, uid, update });
  } catch (error) {
    console.error("Error updating user:", error);
    return NextResponse.json({ error: "Failed to update user." }, { status: 500 });
  }
}
