import { initializeApp, getApps, cert } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
let appOptions: any = {};

if (serviceAccountKey) {
  try {
    const serviceAccount = JSON.parse(serviceAccountKey);
    appOptions = {
      credential: cert(serviceAccount),
      projectId: serviceAccount.project_id,
    };
  } catch (parseError) {
    console.error(
      "Failed to parse FIREBASE_SERVICE_ACCOUNT_KEY JSON:",
      parseError,
    );
  }
} else {
  const fallbackProjectId =
    process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ||
    process.env.GOOGLE_CLOUD_PROJECT;
  if (fallbackProjectId) {
    appOptions = {
      projectId: fallbackProjectId,
    };
  }
}

if (getApps().length === 0) {
  initializeApp(appOptions);
}

const adminAuth = getAuth();
export const adminDb = getFirestore();
export { initializeApp, getApps, cert };

/**
 * Verifies the Request authorization header and validates that the user is an active Admin.
 * Returns the validated UID if successful, or throws an error with a specific status code (e.g. 401, 403).
 */
export async function requireAdmin(req: Request): Promise<string> {
  let idToken: string | null = null;

  // 1. Prefer HttpOnly cookie set by /api/admin/session (set on login)
  const cookieHeader = req.headers.get("cookie") || "";
  const cookieMatch = /(?:^|;\s*)__AdminSession=([^;]+)/.exec(cookieHeader);
  if (cookieMatch) {
    idToken = decodeURIComponent(cookieMatch[1]);
  }

  // 2. Fallback to Authorization: Bearer <idToken>
  if (!idToken) {
    const authHeader = req.headers.get("Authorization");
    if (authHeader && authHeader.startsWith("Bearer ")) {
      idToken = authHeader.substring(7);
    }
  }

  if (!idToken) {
    const error = new Error("Authentication token required.");
    (error as any).status = 401;
    throw error;
  }

  let userUid: string;

  try {
    const decodedToken = await adminAuth.verifyIdToken(idToken);
    userUid = decodedToken.uid;
  } catch (err: any) {
    console.error("Firebase ID Token verification failed:", {
      code: err?.code,
      message: err?.message,
    });
    const error = new Error("Invalid or expired session token.");
    (error as any).status = 401;
    throw error;
  }

  let isAdminActive = false;

  // 1. Try resolving admin status using high-performance Admin SDK if service account is present
  if (serviceAccountKey) {
    try {
      const adminDoc = await adminDb.doc(`admins/${userUid}`).get();
      if (adminDoc.exists) {
        const adminData = adminDoc.data();
        if (adminData && adminData.status !== "disabled") {
          isAdminActive = true;
        }
      }
    } catch (dbError) {
      console.error("Firestore Admin SDK read failed:", dbError);
    }
  }

  // 2. Fallback to Firestore REST API using user's ID token if Admin SDK is unconfigured/credentials missing
  if (!isAdminActive) {
    const projectId =
      process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ||
      process.env.GOOGLE_CLOUD_PROJECT;
    if (projectId) {
      try {
        console.log(
          `Admin status check via Firestore REST fallback for UID: ${userUid}`,
        );
        const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/admins/${userUid}`;
        const res = await fetch(url, {
          headers: {
            Authorization: `Bearer ${idToken}`,
          },
        });

        if (res.ok) {
          const docData = await res.json();
          // Status check: active status is stored under fields.status.stringValue
          const statusField = docData.fields?.status?.stringValue;
          if (statusField !== "disabled") {
            isAdminActive = true;
          }
        } else {
          console.warn(
            `Firestore REST API fallback check returned status: ${res.status}`,
          );
        }
      } catch (fetchError) {
        console.error("Firestore REST API fallback check failed:", fetchError);
      }
    }
  }

  if (!isAdminActive) {
    const error = new Error("Forbidden. Admin access required.");
    (error as any).status = 403;
    throw error;
  }

  return userUid;
}
