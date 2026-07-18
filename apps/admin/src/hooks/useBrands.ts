import { useState, useEffect } from 'react';
import { collection, query, orderBy, onSnapshot, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import type { Brand } from '@/types';

/**
 * Hook to subscribe to brands collection in real-time.
 */
export function useBrands() {
  const [brands, setBrands] = useState<Brand[]>([]);
  const [brandsMap, setBrandsMap] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const q = query(
      collection(db, 'brands'),
      where('status', '==', 'active'),
      orderBy('createdAt', 'desc')
    );
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const list: Brand[] = [];
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
      setBrands(list);
      setBrandsMap(map);
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return { brands, brandsMap, isLoading };
}
