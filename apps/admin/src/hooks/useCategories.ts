import { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import type { Category } from '@/types';

/**
 * Hook to subscribe to categories collection in real-time.
 * Returns categories list and a key→name map for quick lookups.
 */
export function useCategories() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [categoriesMap, setCategoriesMap] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, 'categories'),
      where('status', '==', 'active'),
      orderBy('createdAt', 'desc')
    );
    const unsubscribe = onSnapshot(
      q,
      (snapshot) => {
        const list: Category[] = [];
        const map: Record<string, string> = {};
        snapshot.forEach((doc) => {
          const data = doc.data();
          list.push({
            id: doc.id,
            name: data.name || '',
            createdAt: data.createdAt,
          });
          map[doc.id] = data.name || doc.id;
        });
        setCategories(list);
        setCategoriesMap(map);
        setIsLoading(false);
        setError(null);
      },
      (err) => {
        console.error('Error in useCategories hook:', err);
        setError(err);
        setIsLoading(false);
      }
    );

    return () => unsubscribe();
  }, []);

  return { categories, categoriesMap, isLoading, error };
}
