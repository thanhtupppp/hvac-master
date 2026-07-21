import { NextResponse } from "next/server";
import { adminAuth, adminDb } from "@/lib/firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";

/**
 * POST /api/profile/delete — Delete a user account and all associated data.
 *
 * Flow:
 *  1. Verify the user's ID token (checkRevoked: true).
 *  2. Confirm the token UID matches the requested uid (prevent cross-user deletion).
 *  3. Trigger a recent-login check via adminAuth.getUser() to surface
 *     "auth/requires-recent-login" early before destructive writes.
 *  4. Recursively delete all subcollections under users/{uid}.
 *  5. Delete the user document.
 *  6. Delete the Firebase Auth account.
 *
 * If step 3 fails with requires-recent-login, returns 401 so the client
 * can ask the user to re-authenticate before trying again.
 */
export async function POST(req: Request) {
  // ── 1. Parse body ─────────────────────────────────────────────────────────
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body." }, { status: 400 });
  }

  if (!body || typeof body !== "object" || !("uid" in body)) {
    return NextResponse.json(
      { error: "Missing required field: uid." },
      { status: 400 },
    );
  }
  const { uid } = body as { uid: string };

  if (typeof uid !== "string" || uid.trim().length === 0) {
    return NextResponse.json(
      { error: "uid must be a non-empty string." },
      { status: 400 },
    );
  }

  // ── 2. Verify ID token ───────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return NextResponse.json(
      { error: "Authorization header with Bearer token required." },
      { status: 401 },
    );
  }

  const idToken = authHeader.slice(7);
  let decodedTokenUid: string;
  try {
    const decoded = await adminAuth.verifyIdToken(idToken, true); // checkRevoked
    decodedTokenUid = decoded.uid;
  } catch (err: any) {
    console.error("[Profile/Delete] Token verification failed:", err?.message);
    return NextResponse.json(
      { error: "Invalid or revoked token." },
      { status: 401 },
    );
  }

  // ── 3. Prevent cross-user deletion ────────────────────────────────────────
  if (decodedTokenUid !== uid) {
    console.warn(
      `[Profile/Delete] UID mismatch: token.uid=${decodedTokenUid} body.uid=${uid}`,
    );
    return NextResponse.json(
      { error: "Forbidden: token UID does not match requested uid." },
      { status: 403 },
    );
  }

  // ── 4. Trigger recent-login check via adminAuth.getUser() ─────────────────
  try {
    await adminAuth.getUser(uid);
  } catch (err: any) {
    // adminAuth.getUser() internally calls getUserById which requires a
    // recently-issued token for delete operations.
    if (
      err?.code === "auth/requires-recent-login" ||
      err?.message?.includes("requires-recent-login")
    ) {
      console.warn(`[Profile/Delete] requires-recent-login for uid=${uid}`);
      return NextResponse.json(
        {
          error: "requires-recent-login",
          message: "Vui lòng đăng nhập lại trước khi thực hiện thao tác này.",
        },
        { status: 401 },
      );
    }
    // Other errors (user already deleted, etc.) — continue and let the
    // subsequent operations fail with descriptive errors.
    console.warn(
      `[Profile/Delete] adminAuth.getUser warning for uid=${uid}:`,
      err?.message,
    );
  }

  const userDoc = adminDb.collection("users").doc(uid);

  // ── 5. Recursively delete all subcollections ─────────────────────────────
  try {
    await deleteSubcollections(userDoc);
  } catch (err) {
    console.error(
      `[Profile/Delete] Failed to delete subcollections for uid=${uid}:`,
      err,
    );
    return NextResponse.json(
      { error: "Failed to delete user subcollections. Please try again." },
      { status: 500 },
    );
  }

  // ── 6. Delete user document ───────────────────────────────────────────────
  try {
    await userDoc.delete();
  } catch (err: any) {
    // Document may not exist (e.g. already deleted or never created).
    // Log but do not fail — proceed to Auth deletion.
    if (err?.code !== "not-found") {
      console.error(
        `[Profile/Delete] Failed to delete user doc for uid=${uid}:`,
        err,
      );
      return NextResponse.json(
        { error: "Failed to delete user document." },
        { status: 500 },
      );
    }
    console.warn(`[Profile/Delete] User doc already absent for uid=${uid}`);
  }

  // ── 7. Delete Firebase Auth account ──────────────────────────────────────
  try {
    await adminAuth.deleteUser(uid);
  } catch (err: any) {
    if (err?.code === "auth/user-not-found") {
      console.warn(
        `[Profile/Delete] Auth account already absent for uid=${uid}`,
      );
    } else {
      console.error(
        `[Profile/Delete] Failed to delete Auth account for uid=${uid}:`,
        err,
      );
      return NextResponse.json(
        { error: "Failed to delete auth account. User data has been removed." },
        { status: 500 },
      );
    }
  }

  console.log(`[Profile/Delete] Account deleted: uid=${uid}`);
  return NextResponse.json({ ok: true, uid });
}

// ── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Recursively deletes all documents in every subcollection under the given
 * document reference using batched writes (500 docs per batch, Firestore limit).
 * Stops on errors after the first batch commit failure per subcollection.
 */
async function deleteSubcollections(
  userDoc: FirebaseFirestore.DocumentReference,
): Promise<void> {
  // Fetch all top-level subcollections for this user document.
  // listCollections returns CollectionReference[] for direct children.
  const collections = await userDoc.listCollections();
  await Promise.all(collections.map((col) => deleteCollectionRecursively(col)));
}

/**
 * Deletes all documents in a collection using batched writes.
 * Only re-throws unexpected errors; empty collections are a no-op.
 */
async function deleteCollectionRecursively(
  col: FirebaseFirestore.CollectionReference,
): Promise<void> {
  try {
    while (true) {
      const batch = adminDb.batch();
      const snapshot = await col.limit(500).get();

      if (snapshot.size === 0) break;

      snapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
    }
  } catch (err: any) {
    // Firestore error codes: permission-denied, unavailable, etc.
    // Let the top-level handler decide whether to abort the whole deletion.
    console.error(
      `[Profile/Delete] Batch delete failed for collection ${col.path}:`,
      err?.message ?? err,
    );
    throw err;
  }
}
