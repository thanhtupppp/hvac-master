import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { adminDb } from "@/lib/firebase-admin";
import { z } from "zod";
import { FieldValue } from "firebase-admin/firestore";

const updateSchema = z.object({
  planCode: z
    .string()
    .min(2)
    .max(60)
    .regex(/^[a-z0-9_]+$/)
    .optional(),
  entitlementId: z.string().min(1).optional(),
  name: z.string().min(1).max(100).optional(),
  nameEn: z.string().max(100).optional(),
  description: z.string().max(500).optional(),
  priceVND: z.number().int().nonnegative().optional(),
  priceUSD: z.number().nonnegative().optional(),
  interval: z.enum(["monthly", "quarterly", "yearly", "lifetime"]).optional(),
  durationDays: z.number().int().positive().optional(),
  trialDays: z.number().int().nonnegative().optional(),
  productId: z.string().min(1).optional(),
  provider: z.enum(["google_play", "app_store", "web"]).optional(),
  features: z.array(z.string().max(200)).optional(),
  isFeatured: z.boolean().optional(),
  sortOrder: z.number().int().optional(),
  isActive: z.boolean().optional(),
  badge: z.string().max(50).optional(),
  theme: z.enum(["blue", "purple", "gold"]).optional(),
  internalNote: z.string().max(500).optional(),
});

/**
 * PATCH /api/plans/[id]
 * Admin-only. Updates a single plan.
 */
export async function PATCH(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    await requireAdmin(req);
  } catch (authError: any) {
    return NextResponse.json(
      { error: authError.message },
      { status: authError.status || 401 },
    );
  }

  try {
    const { id } = await params;
    const body = await req.json().catch(() => null);
    const parsed = updateSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Dữ liệu không hợp lệ.", details: parsed.error.format() },
        { status: 400 },
      );
    }

    const docRef = adminDb.collection("subscription_plans").doc(id);
    const existing = await docRef.get();
    if (!existing.exists) {
      return NextResponse.json(
        { error: "Không tìm thấy gói." },
        { status: 404 },
      );
    }

    // If planCode is being changed, ensure uniqueness
    if (parsed.data.planCode) {
      const dup = await adminDb
        .collection("subscription_plans")
        .where("planCode", "==", parsed.data.planCode)
        .limit(1)
        .get();
      if (!dup.empty && dup.docs[0].id !== id) {
        return NextResponse.json(
          { error: `planCode "${parsed.data.planCode}" đã tồn tại.` },
          { status: 409 },
        );
      }
    }

    await docRef.update({
      ...parsed.data,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const updated = await docRef.get();
    return NextResponse.json({ id, ...updated.data() });
  } catch (error) {
    console.error("Error updating plan:", error);
    return NextResponse.json(
      { error: "Failed to update plan." },
      { status: 500 },
    );
  }
}

/**
 * DELETE /api/plans/[id]
 * Admin-only. Hard-deletes a plan. (Soft-delete via PATCH isActive=false.)
 */
export async function DELETE(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    await requireAdmin(req);
  } catch (authError: any) {
    return NextResponse.json(
      { error: authError.message },
      { status: authError.status || 401 },
    );
  }

  try {
    const { id } = await params;
    const docRef = adminDb.collection("subscription_plans").doc(id);
    const existing = await docRef.get();
    if (!existing.exists) {
      return NextResponse.json(
        { error: "Không tìm thấy gói." },
        { status: 404 },
      );
    }

    await docRef.delete();
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("Error deleting plan:", error);
    return NextResponse.json(
      { error: "Failed to delete plan." },
      { status: 500 },
    );
  }
}
