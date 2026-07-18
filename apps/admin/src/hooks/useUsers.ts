"use client";

import { useState, useEffect, useCallback } from "react";
import { auth } from "@/lib/firebase";
import type { UserListItem } from "@/types";

interface UseUsersOptions {
  filter?: "all" | "vip" | "free" | "disabled";
  search?: string;
  limit?: number;
}

export function useUsers({ filter = "all", search = "", limit = 100 }: UseUsersOptions = {}) {
  const [users, setUsers] = useState<UserListItem[]>([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchUsers = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const idToken = await auth.currentUser?.getIdToken();
      const params = new URLSearchParams({ filter, limit: String(limit) });
      if (search) params.set("search", search);

      const res = await fetch(`/api/users?${params}`, {
        headers: { Authorization: `Bearer ${idToken}` },
      });
      if (!res.ok) throw new Error("Không thể tải danh sách người dùng.");
      const data = await res.json();
      setUsers(data.users || []);
      setTotal(data.total || 0);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  }, [filter, search, limit]);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  const updateUser = async (uid: string, updates: {
    isPremium?: boolean;
    status?: "active" | "disabled";
    premiumDays?: number;
  }) => {
    const idToken = await auth.currentUser?.getIdToken();
    const res = await fetch("/api/users", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${idToken}`,
      },
      body: JSON.stringify({ uid, ...updates }),
    });
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      throw new Error(data.error || "Cập nhật thất bại.");
    }
    await fetchUsers(); // Refresh list
    return res.json();
  };

  return { users, total, isLoading, error, refetch: fetchUsers, updateUser };
}
