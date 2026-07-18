"use client";

import { useState, useEffect, useCallback } from "react";
import { auth } from "@/lib/firebase";
import type { Payment, PaymentStats } from "@/types";

interface UsePaymentsOptions {
  filter?: "all" | "active" | "expired" | "cancelled" | "refunded" | "pending";
  search?: string;
  limit?: number;
}

export function usePayments({ filter = "all", search = "", limit = 100 }: UsePaymentsOptions = {}) {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [stats, setStats] = useState<PaymentStats>({ activeSubscribers: 0, revenueThisMonth: 0, newThisWeek: 0, pendingCount: 0 });
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPayments = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const idToken = await auth.currentUser?.getIdToken();
      const params = new URLSearchParams({ filter, limit: String(limit) });
      if (search) params.set("search", search);

      const res = await fetch(`/api/payments?${params}`, {
        headers: { Authorization: `Bearer ${idToken}` },
      });
      if (!res.ok) throw new Error("Không thể tải danh sách thanh toán.");
      const data = await res.json();
      setPayments(data.payments || []);
      setTotal(data.total || 0);
      if (data.stats) setStats(data.stats);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  }, [filter, search, limit]);

  useEffect(() => { fetchPayments(); }, [fetchPayments]);

  const syncPayment = async (payload: {
    purchaseToken: string;
    productId: string;
    purchaseType?: "subscription" | "inapp";
    userId?: string;
    userEmail?: string;
  }) => {
    const idToken = await auth.currentUser?.getIdToken();
    const res = await fetch("/api/payments", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify(payload),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || "Sync thất bại.");
    await fetchPayments();
    return data;
  };

  const updatePaymentStatus = async (id: string, status: Payment["status"], note?: string) => {
    const idToken = await auth.currentUser?.getIdToken();
    const res = await fetch("/api/payments", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify({ id, status, note }),
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      throw new Error(data.error || "Cập nhật thất bại.");
    }
    await fetchPayments();
  };

  return { payments, stats, total, isLoading, error, refetch: fetchPayments, syncPayment, updatePaymentStatus };
}
