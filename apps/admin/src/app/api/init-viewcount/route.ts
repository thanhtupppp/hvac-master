import { NextResponse } from "next/server";
import { db } from "@/lib/firebase";
import { collection, getDocs, writeBatch, doc } from "firebase/firestore";

export async function POST() {
  try {
    const articlesRef = collection(db, "articles");
    const snapshot = await getDocs(articlesRef);

    let updatedCount = 0;
    let batchCount = 0;
    let batch = writeBatch(db);

    for (const docSnap of snapshot.docs) {
      const data = docSnap.data();

      // Only set viewCount if it doesn't exist yet
      if (data.viewCount === undefined || data.viewCount === null) {
        batch.update(doc(db, "articles", docSnap.id), { viewCount: 0 });
        updatedCount++;
        batchCount++;

        // Firestore batch limit is 500
        if (batchCount >= 400) {
          await batch.commit();
          batch = writeBatch(db);
          batchCount = 0;
        }
      }
    }

    // Commit remaining
    if (batchCount > 0) {
      await batch.commit();
    }

    return NextResponse.json({
      success: true,
      message: `Đã khởi tạo viewCount cho ${updatedCount}/${snapshot.size} bài viết.`,
      total: snapshot.size,
      updated: updatedCount,
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return NextResponse.json(
      { success: false, error: message },
      { status: 500 }
    );
  }
}
