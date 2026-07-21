"use client";

import React, {
  createContext,
  useContext,
  useEffect,
  useState,
  useMemo,
} from "react";
import { onAuthStateChanged, User, signOut } from "firebase/auth";
import { auth, db } from "@/lib/firebase";
import { doc, getDoc } from "firebase/firestore";

interface AuthContextType {
  user: User | null;
  loading: boolean;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  logout: async () => {},
});

export const useAuth = () => useContext(AuthContext);

async function logout() {
  try {
    await signOut(auth);
  } catch (error) {
    console.error("Error signing out: ", error);
  } finally {
    if (typeof window !== "undefined") {
      try {
        await fetch("/api/admin/session", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ action: "clear" }),
        });
      } catch {
        // best-effort cookie cleanup; logout still proceeds
      }
    }
  }
}

async function persistSessionCookie(uid: string): Promise<boolean> {
  if (typeof window === "undefined") return false;
  const idToken = await window.auth?.currentUser?.getIdToken?.();
  if (!idToken) return false;
  try {
    const res = await fetch("/api/admin/session", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "set", idToken }),
    });
    return res.ok;
  } catch {
    return false;
  }
}

async function clearSessionCookie(): Promise<void> {
  if (typeof window === "undefined") return;
  try {
    await fetch("/api/admin/session", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "clear" }),
    });
  } catch {
    // best-effort
  }
}

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setLoading(true);
      if (currentUser) {
        try {
          const adminDoc = await getDoc(doc(db, "admins", currentUser.uid));
          if (adminDoc.exists()) {
            setUser(currentUser);
            await persistSessionCookie(currentUser.uid);
          } else {
            setUser(null);
            await clearSessionCookie();
            await signOut(auth);
            if (typeof window !== "undefined") {
              window.location.href = "/login?error=unauthorized";
            }
          }
        } catch (error) {
          console.error("Error checking admin status in AuthContext:", error);
          setUser(null);
          await clearSessionCookie();
          await signOut(auth);
        }
      } else {
        setUser(null);
        await clearSessionCookie();
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const contextValue = useMemo(
    () => ({ user, loading, logout }),
    [user, loading],
  );

  return (
    <AuthContext.Provider value={contextValue}>{children}</AuthContext.Provider>
  );
};
