import { db } from "@/lib/firebase";
import { doc, runTransaction, deleteDoc, serverTimestamp, collection, query, where, getDocs, limit } from "firebase/firestore";

/**
 * Creates a new brand in Firestore atomically using a transaction to prevent race conditions.
 * @param slug The unique normalized slug identifier for the brand.
 * @param name The display name of the brand.
 */
export async function createBrand(slug: string, name: string): Promise<void> {
  const ref = doc(db, "brands", slug);

  await runTransaction(db, async (transaction) => {
    const snap = await transaction.get(ref);

    if (snap.exists()) {
      throw new Error(`Hãng sản xuất (Slug ID) "${slug}" đã tồn tại.`);
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
 * Checks for referencing articles and removes a brand from Firestore if safe.
 * @param id The ID (slug) of the brand to remove.
 */
export async function removeBrand(id: string): Promise<void> {
  // Check if any articles are currently referencing this brand
  const articlesRef = collection(db, "articles");
  const q = query(articlesRef, where("brand", "==", id), limit(1));
  const snap = await getDocs(q);

  if (!snap.empty) {
    throw new Error("Không thể xóa hãng sản xuất này vì đang có bài viết tham chiếu tới nó.");
  }

  const ref = doc(db, "brands", id);
  await deleteDoc(ref);
}
