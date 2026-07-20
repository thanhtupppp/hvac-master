"use client";

import { useState, useEffect } from "react";
import { auth } from "@/lib/firebase";
import type { RevenueCatAnalytics } from "@/types";

export function useRevenueCatAnalytics() {
  const [analytics, setAnalytics] = useState<RevenueCatAnalytics | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setIsLoading(true);
    setError(null);

    auth.currentUser?.getIdToken().then((idToken) => {
      if (cancelled) return;
      fetch("/api/analytics/revenuecat", {
        headers: { Authorization: `Bearer ${idToken}` },
      })
        .then((res) => {
          if (res.status === 503) return res.json();
          if (!res.ok) throw new Error("Không thể tải RevenueCat analytics.");
          return res.json();
        })
        .then((data) => {
          if (cancelled) return;
          if (data.error) {
            // RevenueCat not configured — silent, don't show as error
            setAnalytics(null);
          } else {
            setAnalytics(data);
          }
        })
        .catch((err: any) => {
          if (cancelled) return;
          setError(err.message);
        })
        .finally(() => {
          if (!cancelled) setIsLoading(false);
        });
    });

    return () => {
      cancelled = true;
    };
  }, []);

  return { analytics, isLoading, error };
}
