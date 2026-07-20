import { NextResponse } from "next/server";
import { adminDb } from "@/lib/firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

/**
 * GET /api/cron/vip-expiry
 *
 * Vercel Cron: runs daily to revoke expired VIP subscriptions.
 * Configure in vercel.json:
 *   { "crons": [{ "path": "/api/cron/vip-expiry", "schedule": "0 6 * * *" }] }
 *
 * Also registers itself in Firestore for auditability.
 *
 * Falls back to admin-key header auth in dev/test environments where cron is not configured.
 */

// Only allow cron requests (Vercel sets this header) or admin secret in dev
function isAuthorized(req: Request): boolean {
  const vercelHeader = req.headers.get("x-vercel-signature");
  const cronHeader = req.headers.get("x-cron-auth");
  const adminKey = process.env.CRON_SECRET_KEY;

  if (vercelHeader) return true;
  if (cronHeader && adminKey && cronHeader === adminKey) return true;
  // In development without auth headers, allow but log
  if (process.env.NODE_ENV === "development") return true;
  return false;
}

export async function GET(req: Request) {
  if (!isAuthorized(req)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const now = Timestamp.now();

  try {
    // Find all active VIP users whose expiry time has passed
    const expiredSnap = await adminDb
      .collection("users")
      .where("isPremium", "==", true)
      .get();

    const batch = adminDb.batch();
    const nowMillis = Date.now();
    let revokedCount = 0;

    for (const doc of expiredSnap.docs) {
      const data = doc.data();
      const expiry = data.premiumExpiry;

      if (!expiry) continue;

      const expiryDate =
        expiry.toDate?.() ||
        (typeof expiry === "string" ? new Date(expiry) : null);

      if (!expiryDate || expiryDate.getTime() > nowMillis) continue;

      batch.update(doc.ref, {
        isPremium: false,
        premiumExpiry: null,
        updatedAt: FieldValue.serverTimestamp(),
        // Note: keep activeSubscriptionId for audit
      });

      revokedCount++;
    }

    if (revokedCount > 0) {
      await batch.commit();
    }

    // Log cron run for audit trail
    await adminDb.collection("cron_runs").add({
      job: "vip_expiry",
      revokedCount,
      runAt: FieldValue.serverTimestamp(),
      success: true,
    });

    console.log(`[VIP Expiry Cron] Revoked ${revokedCount} expired VIPs.`);
    return NextResponse.json({
      ok: true,
      revokedCount,
      runAt: new Date().toISOString(),
    });
  } catch (err) {
    console.error("[VIP Expiry Cron] Error:", err);

    // Log failed run
    try {
      await adminDb.collection("cron_runs").add({
        job: "vip_expiry",
        runAt: FieldValue.serverTimestamp(),
        success: false,
        error: String(err),
      });
    } catch {}

    return NextResponse.json({ error: "Cron job failed." }, { status: 500 });
  }
}
