"use client";

import { useState, useEffect, useCallback } from "react";
import { auth } from "@/lib/firebase";

export interface PaymentAnalytics {
  mrr: number;
  mrrFormatted: string;
  activeSubscriptions: number;
  activeInApps: number;
  totalActive: number;
  vipCount: number;
  totalUsers: number;
  vipRate: number;
  newSubsThisMonth: number;
  newSubsLastMonth: number;
  churnedThisMonth: number;
  churnRate: number;
  refundRate: number;
  revenueByMonth: { month: string; revenue: number }[];
  topProducts: { productId: string; revenue: number; count: number }[];
  generatedAt: string;
}

export function usePaymentsAnalytics() {
  const [analytics, setAnalytics] = useState<PaymentAnalytics | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadAnalytics = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const idToken = await auth.currentUser?.getIdToken();
      const res = await fetch("/api/payments/analytics", {
        headers: { Authorization: `Bearer ${idToken}` },
      });
      if (!res.ok) throw new Error("Không thể tải analytics.");
      const data = await res.json();
      setAnalytics(data);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadAnalytics();
  }, [loadAnalytics]);

  return { analytics, isLoading, error, refetch: loadAnalytics };
}
