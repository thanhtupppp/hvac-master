import { db } from "@/lib/firebase";
import { doc, updateDoc, serverTimestamp } from "firebase/firestore";

/**
 * Removes an article from Firestore (Soft delete).
 * @param id The ID of the article to remove.
 */
export async function removeArticle(id: string): Promise<void> {
  const ref = doc(db, "articles", id);
  
  // Soft delete to preserve audit history and prevent broken referencing
  await updateDoc(ref, {
    status: "deleted",
    deletedAt: serverTimestamp(),
  });
}
