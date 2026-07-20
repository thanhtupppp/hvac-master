import { NextResponse } from "next/server";
import { adminDb } from "@/lib/firebase-admin";

/**
 * GET /api/plans/active
 *
 * Public endpoint — returns only ACTIVE plans, sorted by sortOrder.
 * Used by the Flutter mobile app to display the paywall.
 *
 * No authentication required: active plan list is public marketing data.
 * Sensitive fields (internalNote, etc.) are stripped.
 *
 * Cached via CDN-friendly headers (5 min) since plans change rarely.
 */
export async function GET() {
  try {
    const snap = await adminDb
      .collection("subscription_plans")
      .where("isActive", "==", true)
      .orderBy("sortOrder", "asc")
      .get();

    const plans = snap.docs.map((d) => {
      const data = d.data();
      // Strip admin-only fields
      const { internalNote, ...publicData } = data as any;
      return { id: d.id, ...publicData };
    });

    return NextResponse.json(
      { plans },
      {
        headers: {
          // Mobile clients can cache for 5 minutes; CDN may cache longer.
          "Cache-Control": "public, s-maxage=300, stale-while-revalidate=600",
        },
      },
    );
  } catch (error) {
    console.error("Error fetching active plans:", error);
    return NextResponse.json(
      { error: "Failed to fetch plans." },
      { status: 500 },
    );
  }
}
