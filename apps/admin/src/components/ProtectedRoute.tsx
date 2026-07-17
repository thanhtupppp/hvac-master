"use client";

import { useAuth } from "@/contexts/AuthContext";
import { useRouter, usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { db } from "@/lib/firebase";
import { doc, getDoc } from "firebase/firestore";

export default function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();
  const [checkingAdmin, setCheckingAdmin] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    async function checkAdminStatus() {
      if (loading) return;
      if (!user) {
        setCheckingAdmin(false);
        setIsAdmin(false);
        if (pathname !== "/login") {
          router.push("/login");
        }
        return;
      }

      try {
        const adminDoc = await getDoc(doc(db, "admins", user.uid));
        if (adminDoc.exists()) {
          setIsAdmin(true);
        } else {
          setIsAdmin(false);
          await logout();
          router.push("/login?error=unauthorized");
        }
      } catch (error) {
        console.error("Error checking admin status:", error);
        setIsAdmin(false);
        await logout();
        router.push("/login?error=error");
      } finally {
        setCheckingAdmin(false);
      }
    }

    checkAdminStatus();
  }, [user, loading, router, pathname]);

  if (loading || (user && checkingAdmin)) {
    return (
      <div className="flex h-screen w-full items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!user || !isAdmin) {
    return null;
  }

  return <>{children}</>;
}
