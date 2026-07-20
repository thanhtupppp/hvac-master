"use client";

import { useState, useEffect, useCallback } from "react";
import { auth } from "@/lib/firebase";
import type { SubscriptionPlan } from "@/types";

export function usePlans() {
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const idToken = await auth.currentUser?.getIdToken();
      const res = await fetch("/api/plans", {
        headers: { Authorization: `Bearer ${idToken}` },
      });
      if (!res.ok) throw new Error("Không thể tải danh sách gói.");
      const data = await res.json();
      setPlans(data.plans || []);
      setTotal(data.total || 0);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const createPlan = async (
    input: Omit<SubscriptionPlan, "id" | "createdAt" | "updatedAt">,
  ) => {
    const idToken = await auth.currentUser?.getIdToken();
    const res = await fetch("/api/plans", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify(input),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || "Tạo gói thất bại.");
    await load();
    return data;
  };

  const updatePlan = async (id: string, patch: Partial<SubscriptionPlan>) => {
    const idToken = await auth.currentUser?.getIdToken();
    const res = await fetch(`/api/plans/${id}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify(patch),
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || "Cập nhật gói thất bại.");
    await load();
    return data;
  };

  const deletePlan = async (id: string) => {
    if (!confirm("Xoá hẳn gói này? Hành động không thể hoàn tác.")) return;
    const idToken = await auth.currentUser?.getIdToken();
    const res = await fetch(`/api/plans/${id}`, {
      method: "DELETE",
      headers: { Authorization: `Bearer ${idToken}` },
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || "Xoá gói thất bại.");
    await load();
    return data;
  };

  const toggleActive = async (id: string, isActive: boolean) => {
    return updatePlan(id, { isActive });
  };

  return {
    plans,
    total,
    isLoading,
    error,
    refetch: load,
    createPlan,
    updatePlan,
    deletePlan,
    toggleActive,
  };
}
