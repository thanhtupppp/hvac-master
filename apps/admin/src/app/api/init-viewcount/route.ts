import { NextResponse } from "next/server";
import { requireAdmin, adminDb } from "@/lib/firebase-admin";
import { z } from "zod";

const requestBodySchema = z.object({
  limit: z
    .number()
    .int()
    .positive()
    .max(400, "Giới hạn tối đa 400 bài viết mỗi lượt")
    .optional()
    .default(100),
  lastDocId: z.string().trim().optional(),
});

export async function POST(req: Request) {
  try {
    // 1. Authenticate & Authorize request using requireAdmin helper
    try {
      await requireAdmin(req);
    } catch (authError: any) {
      return NextResponse.json(
        { error: authError.message || "Unauthorized access." },
        { status: authError.status || 401 }
      );
    }

    // 2. Parse and Validate input payload
    const body = await req.json().catch(() => null);
    const parsed = requestBodySchema.safeParse(body || {});
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Dữ liệu đầu vào không hợp lệ.", details: parsed.error.format() },
        { status: 400 }
      );
    }

    const { limit, lastDocId } = parsed.data;

    // 3. Construct chunked query using document ID ordering
    const articlesRef = adminDb.collection("articles");
    let queryRef = articlesRef.orderBy("__name__").limit(limit);

    if (lastDocId) {
      const lastDocSnap = await articlesRef.doc(lastDocId).get();
      if (!lastDocSnap.exists) {
        return NextResponse.json(
          { error: `Không tìm thấy tài liệu định danh cursor tương ứng với ID: ${lastDocId}` },
          { status: 400 }
        );
      }
      queryRef = queryRef.startAfter(lastDocSnap);
    }

    const snapshot = await queryRef.get();

    // 4. Batch update chunk documents
    let updatedCount = 0;
    let batchCount = 0;
    let batch = adminDb.batch();

    for (const docSnap of snapshot.docs) {
      const data = docSnap.data();

      // Only initialize viewCount to 0 if it is missing (to protect existing stats)
      if (data.viewCount === undefined || data.viewCount === null) {
        const docRef = articlesRef.doc(docSnap.id);
        batch.update(docRef, { viewCount: 0 });
        updatedCount++;
        batchCount++;

        // Commit batch when reaching Firestore transaction limit threshold
        if (batchCount >= 400) {
          await batch.commit();
          batch = adminDb.batch();
          batchCount = 0;
        }
      }
    }

    // Commit any remaining updates
    if (batchCount > 0) {
      await batch.commit();
    }

    const lastDoc = snapshot.docs[snapshot.docs.length - 1];
    const nextCursor = snapshot.docs.length === limit && lastDoc ? lastDoc.id : null;

    return NextResponse.json({
      success: true,
      message: `Đã khởi tạo viewCount cho ${updatedCount}/${snapshot.docs.length} bài viết trong trang này.`,
      processed: snapshot.docs.length,
      updated: updatedCount,
      nextCursor: nextCursor, // Returns the ID of the last document to use as cursor for the next chunk request
    });
  } catch (error) {
    console.error("Error in init-viewcount route:", error);
    return NextResponse.json(
      { error: "Internal server error occurred during viewcount initialization." },
      { status: 500 }
    );
  }
}
