import { useState, useEffect } from "react";
import {
  collection,
  query,
  orderBy,
  onSnapshot,
  getDocs,
  where,
  getCountFromServer,
} from "firebase/firestore";
import { db } from "@/lib/firebase";
import type { ArticleListItem } from "@/types";

/**
 * Hook to subscribe to articles collection in real-time.
 * Provides article list, total count, and loading state.
 */
export function useArticles(limitCount?: number) {
  const [articles, setArticles] = useState<ArticleListItem[]>([]);
  const [totalCount, setTotalCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, "articles"),
      where("status", "==", "active"),
      orderBy("createdAt", "desc"),
    );
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        setTotalCount(snapshot.size);

        const list: ArticleListItem[] = [];
        let count = 0;
        snapshot.forEach((doc) => {
          if (limitCount && count >= limitCount) return;
          const data = doc.data();
          list.push({
            id: doc.id,
            titleVi: data.title_vi || "",
            category: data.category || "",
            brand: data.brand || "",
            isPremium: data.isPremium || false,
            views: data.views || 0,
            createdAt: data.createdAt,
          });
          count++;
        });
        setArticles(list);
        setIsLoading(false);
        setError(null);
      },
      (err) => {
        console.error("Error in useArticles hook:", err);
        setError(err);
        setIsLoading(false);
      },
    );

    return () => unsubscribe();
  }, [limitCount]);

  return { articles, totalCount, isLoading, error };
}

/**
 * Hook to fetch user stats from Firestore.
 */
export function useUserStats() {
  const [usersCount, setUsersCount] = useState(0);
  const [vipCount, setVipCount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const fetchStats = async () => {
      setIsLoading(true);
      try {
        const [totalSnap, vipSnap] = await Promise.all([
          getCountFromServer(collection(db, "users")),
          getCountFromServer(
            query(collection(db, "users"), where("isPremium", "==", true)),
          ),
        ]);
        setUsersCount(totalSnap.data().count);
        setVipCount(vipSnap.data().count);
        setError(null);
      } catch (err: any) {
        console.error("Error fetching users stats:", err);
        setError(err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchStats();
  }, []);

  return { usersCount, vipCount, isLoading, error };
}
