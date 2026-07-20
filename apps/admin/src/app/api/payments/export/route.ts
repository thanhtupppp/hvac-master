import { NextResponse } from "next/server";
import { requireAdmin } from "@/lib/firebase-admin";
import { adminDb } from "@/lib/firebase-admin";

/**
 * GET /api/payments/export?format=csv
 *
 * Exports all payment records as a CSV file.
 * Admin-only. Returns CSV with Content-Disposition header for browser download.
 *
 * Query params:
 *   - format: "csv" (default) — for future: "xlsx", "pdf"
 *   - status: filter by status ("active", "expired", etc.)
 *   - from: ISO date string, filter purchases from this date
 *   - to: ISO date string, filter purchases until this date
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
    const url = new URL(req.url);
    const status = url.searchParams.get("status");
    const from = url.searchParams.get("from");
    const to = url.searchParams.get("to");

    let query: FirebaseFirestore.Query = adminDb
      .collection("payments")
      .orderBy("purchaseTime", "desc");

    if (status && status !== "all") {
      query = query.where("status", "==", status);
    }
    if (from) {
      query = query.where("purchaseTime", ">=", new Date(from));
    }
    if (to) {
      query = query.where("purchaseTime", "<=", new Date(to));
    }

    const snapshot = await query.get();
    const payments = snapshot.docs.map((doc) => {
      const d = doc.data();
      const purchaseTime = d.purchaseTime?.toDate?.()
        ? d.purchaseTime.toDate().toISOString()
        : "";
      const expiryTime = d.expiryTime?.toDate?.()
        ? d.expiryTime.toDate().toISOString()
        : "";
      const verifiedAt = d.verifiedAt?.toDate?.()
        ? d.verifiedAt.toDate().toISOString()
        : "";
      return {
        id: doc.id,
        orderId: d.orderId || doc.id,
        productId: d.productId || "",
        purchaseType: d.purchaseType || "",
        status: d.status || "",
        amount: d.amount || 0,
        currency: d.currency || "",
        autoRenewing:
          d.autoRenewing == null ? "" : d.autoRenewing ? "Yes" : "No",
        userId: d.userId || "",
        userEmail: d.userEmail || "",
        purchaseTime,
        expiryTime,
        verifiedAt,
        store: d.store || "",
        periodType: d.periodType || "",
        revenuecatEventType: d.revenuecatEventType || "",
        revenuecatTransactionId: d.revenuecatTransactionId || "",
      };
    });

    const csvHeader =
      "ID,Order ID,Product ID,Type,Status,Amount,Currency,Auto-Renewing,User ID,User Email,Purchase Time,Expiry Time,Verified At,Store,Period Type,RC Event Type,RC Transaction ID\n";

    const csvRows = payments.map((p) =>
      [
        escape(p.id),
        escape(p.orderId),
        escape(p.productId),
        escape(p.purchaseType),
        escape(p.status),
        p.amount,
        escape(p.currency),
        escape(p.autoRenewing),
        escape(p.userId),
        escape(p.userEmail),
        escape(p.purchaseTime),
        escape(p.expiryTime),
        escape(p.verifiedAt),
        escape(p.store),
        escape(p.periodType),
        escape(p.revenuecatEventType),
        escape(p.revenuecatTransactionId),
      ].join(","),
    );

    // BOM so Excel opens Vietnamese UTF-8 correctly
    const csv = "\uFEFF" + csvHeader + csvRows.join("\n");
    const timestamp = new Date().toISOString().slice(0, 10);

    return new NextResponse(csv, {
      status: 200,
      headers: {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": `attachment; filename="payments-${timestamp}.csv"`,
      },
    });
  } catch (error) {
    console.error("Error exporting payments:", error);
    return NextResponse.json(
      { error: "Failed to export payments." },
      { status: 500 },
    );
  }
}

/** Escape a value for CSV — wrap in quotes if contains comma, newline, or quote.
 *  Prefix `'` on cells that start with =, +, -, @ to prevent CSV/formula injection. */
function escape(value: string | number): string {
  let str = String(value);
  if (/^[=+\-@\t\r]/.test(str)) {
    str = "'" + str;
  }
  if (str.includes(",") || str.includes("\n") || str.includes('"')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}
