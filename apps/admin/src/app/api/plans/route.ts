import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { adminDb } from "@/lib/firebase-admin";
import { z } from "zod";
import { FieldValue } from "firebase-admin/firestore";

const planSchema = z.object({
  planCode: z
    .string()
    .min(2)
    .max(60)
    .regex(/^[a-z0-9_]+$/, "planCode chỉ gồm chữ thường, số, gạch dưới"),
  entitlementId: z.string().min(1).default("vip"),
  name: z.string().min(1).max(100),
  nameEn: z.string().max(100).optional(),
  description: z.string().max(500).optional(),
  priceVND: z.number().int().nonnegative(),
  priceUSD: z.number().nonnegative().optional(),
  interval: z.enum(["monthly", "quarterly", "yearly", "lifetime"]),
  durationDays: z.number().int().positive().optional(),
  trialDays: z.number().int().nonnegative().default(0),
  productId: z.string().min(1),
  provider: z.enum(["google_play", "app_store", "web"]).default("google_play"),
  features: z.array(z.string().max(200)).default([]),
  isFeatured: z.boolean().default(false),
  sortOrder: z.number().int().default(0),
  isActive: z.boolean().default(true),
  badge: z.string().max(50).optional(),
  theme: z.enum(["blue", "purple", "gold"]).default("blue"),
  internalNote: z.string().max(500).optional(),
});

/**
 * GET /api/plans
 * Admin-only. Lists all subscription plans (sorted by sortOrder asc).
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
    const snap = await adminDb
      .collection("subscription_plans")
      .orderBy("sortOrder", "asc")
      .get();

    const plans = snap.docs.map((d) => ({ id: d.id, ...d.data() }));

    return NextResponse.json({ plans, total: plans.length });
  } catch (error) {
    console.error("Error listing plans:", error);
    return NextResponse.json(
      { error: "Failed to fetch plans." },
      { status: 500 },
    );
  }
}

/**
 * POST /api/plans
 * Admin-only. Creates a new subscription plan.
 */
export async function POST(req: Request) {
  try {
    await requireAdmin(req);
  } catch (authError: any) {
    return NextResponse.json(
      { error: authError.message },
      { status: authError.status || 401 },
    );
  }

  try {
    const body = await req.json().catch(() => null);
    const parsed = planSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Dữ liệu không hợp lệ.", details: parsed.error.format() },
        { status: 400 },
      );
    }

    const data = parsed.data;

    // Validate: lifetime must not have trial, must have durationDays=null
    if (data.interval === "lifetime" && data.trialDays > 0) {
      return NextResponse.json(
        { error: "Gói trọn đời không hỗ trợ dùng thử." },
        { status: 400 },
      );
    }

    // Ensure planCode unique
    const existing = await adminDb
      .collection("subscription_plans")
      .where("planCode", "==", data.planCode)
      .limit(1)
      .get();
    if (!existing.empty) {
      return NextResponse.json(
        { error: `planCode "${data.planCode}" đã tồn tại.` },
        { status: 409 },
      );
    }

    // Ensure productId unique within provider
    const dupProduct = await adminDb
      .collection("subscription_plans")
      .where("productId", "==", data.productId)
      .where("provider", "==", data.provider)
      .limit(1)
      .get();
    if (!dupProduct.empty) {
      return NextResponse.json(
        {
          error: `Product ID "${data.productId}" đã tồn tại trong ${data.provider}.`,
        },
        { status: 409 },
      );
    }

    const docRef = await adminDb.collection("subscription_plans").add({
      ...data,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    const newDoc = await docRef.get();
    return NextResponse.json(
      { id: docRef.id, ...newDoc.data() },
      { status: 201 },
    );
  } catch (error) {
    console.error("Error creating plan:", error);
    return NextResponse.json(
      { error: "Failed to create plan." },
      { status: 500 },
    );
  }
}
