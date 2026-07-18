import { db } from "@/lib/firebase";
import { doc, runTransaction, deleteDoc, serverTimestamp, collection, query, where, getDocs, limit } from "firebase/firestore";

/**
 * Creates a new category in Firestore atomically using a transaction to prevent race conditions.
 * @param slug The unique normalized slug identifier for the category.
 * @param name The display name of the category.
 */
export async function createCategory(slug: string, name: string): Promise<void> {
  const ref = doc(db, "categories", slug);

  await runTransaction(db, async (transaction) => {
    const snap = await transaction.get(ref);

    if (snap.exists()) {
      throw new Error(`Mã chuyên mục (Slug ID) "${slug}" đã tồn tại.`);
    }

    transaction.set(ref, {
      name,
      slug,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  });
}

/**
 * Checks for referencing articles and removes a category from Firestore if safe.
 * @param id The ID (slug) of the category to remove.
 */
export async function removeCategory(id: string): Promise<void> {
  // Check if any articles are currently referencing this category
  const articlesRef = collection(db, "articles");
  const q = query(articlesRef, where("category", "==", id), limit(1));
  const snap = await getDocs(q);

  if (!snap.empty) {
    throw new Error("Không thể xóa chuyên mục này vì đang có bài viết tham chiếu tới nó.");
  }

  const ref = doc(db, "categories", id);
  await deleteDoc(ref);
}
