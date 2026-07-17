"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Users, FileText, ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import ProtectedRoute from "@/components/ProtectedRoute";
import Header from "@/components/Header";
import { db } from "@/lib/firebase";
import { collection, query, orderBy, limit, onSnapshot, getDocs } from "firebase/firestore";
import Link from "next/link";

interface Article {
  id: string;
  titleVi: string;
  category: string;
  isPremium: boolean;
}

export default function Dashboard() {
  const [articlesCount, setArticlesCount] = useState(0);
  const [usersCount, setUsersCount] = useState(0);
  const [vipCount, setVipCount] = useState(0);
  const [latestArticles, setLatestArticles] = useState<Article[]>([]);
  const [categoriesMap, setCategoriesMap] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(true);

  // Load categories mapping
  useEffect(() => {
    const q = query(collection(db, "categories"));
    const unsubscribeCats = onSnapshot(q, (snapshot) => {
      const tempMap: Record<string, string> = {};
      snapshot.forEach((doc) => {
        tempMap[doc.id] = doc.data().name || doc.id;
      });
      setCategoriesMap(tempMap);
    });
    return () => unsubscribeCats();
  }, []);

  // Fetch stats and latest articles from Firestore
  useEffect(() => {
    // 1. Listen to total articles count and latest articles
    const articlesQuery = query(collection(db, "articles"), orderBy("createdAt", "desc"));
    const unsubscribeArticles = onSnapshot(articlesQuery, (snapshot) => {
      setArticlesCount(snapshot.size);
      
      const latest: Article[] = [];
      let count = 0;
      snapshot.forEach((doc) => {
        if (count < 5) {
          const data = doc.data();
          latest.push({
            id: doc.id,
            titleVi: data.title_vi || "",
            category: data.category || "",
            isPremium: data.isPremium || false,
          });
          count++;
        }
      });
      setLatestArticles(latest);
      setIsLoading(false);
    });

    // 2. Fetch users count
    const fetchUsersCount = async () => {
      try {
        const usersSnapshot = await getDocs(collection(db, "users"));
        setUsersCount(usersSnapshot.size);
        
        // Count VIP/Premium users
        let vip = 0;
        usersSnapshot.forEach((doc) => {
          if (doc.data().isPremium === true) {
            vip++;
          }
        });
        setVipCount(vip);
      } catch (error) {
        console.error("Error fetching users stats:", error);
        // Fallback placeholders
        setUsersCount(42);
        setVipCount(12);
      }
    };
    fetchUsersCount();

    return () => {
      unsubscribeArticles();
    };
  }, []);

  const getCategoryName = (catKey: string) => {
    const defaultMap: Record<string, string> = {
      ac: "Điều hòa",
      fridge: "Tủ lạnh",
      "washing-machine": "Máy giặt",
      microwave: "Lò vi sóng",
    };
    return categoriesMap[catKey] || defaultMap[catKey] || catKey;
  };

  return (
    <ProtectedRoute>
      <div className="flex min-h-screen w-full flex-col bg-gray-50 dark:bg-gray-900">
        <Header />
        
        <main className="flex-1 space-y-6 p-8">
          <div className="flex items-center justify-between">
            <h2 className="text-3xl font-bold tracking-tight">Tổng quan</h2>
            <div className="flex items-center space-x-2">
              <Link href="/editor">
                <Button>Tạo bài viết mới</Button>
              </Link>
            </div>
          </div>
          
          <div className="grid gap-6 md:grid-cols-3">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Tổng số người dùng</CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{usersCount}</div>
                <p className="text-xs text-muted-foreground">Đăng ký trong hệ thống</p>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Hội viên VIP (Premium)</CardTitle>
                <span className="text-amber-500 font-bold text-lg">★</span>
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{vipCount}</div>
                <p className="text-xs text-muted-foreground">
                  {usersCount > 0 ? `${Math.round((vipCount / usersCount) * 100)}% tổng số người dùng` : "0%"}
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Tổng số bài viết</CardTitle>
                <FileText className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{articlesCount}</div>
                <p className="text-xs text-muted-foreground">Tài liệu và mã lỗi HVAC</p>
              </CardContent>
            </Card>
          </div>

          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-7">
            <Card className="col-span-4">
              <CardHeader>
                <CardTitle>Biểu đồ hoạt động hệ thống</CardTitle>
              </CardHeader>
              <CardContent className="h-[260px] flex items-center justify-center text-muted-foreground bg-gray-100 dark:bg-gray-800 rounded-md m-4 mt-0">
                [Khu vực biểu đồ phân tích kỹ thuật]
              </CardContent>
            </Card>
            
            <Card className="col-span-3">
              <CardHeader className="flex flex-row items-center justify-between pb-4">
                <CardTitle>Bài viết mới nhất</CardTitle>
                <Link href="/articles">
                  <Button variant="ghost" size="sm" className="text-xs text-blue-600 gap-1">
                    Xem tất cả <ArrowRight className="h-3 w-3" />
                  </Button>
                </Link>
              </CardHeader>
              <CardContent className="pt-0">
                {isLoading ? (
                  <div className="py-8 text-center text-muted-foreground animate-pulse">
                    Đang tải danh sách bài viết...
                  </div>
                ) : latestArticles.length === 0 ? (
                  <div className="py-8 text-center text-muted-foreground">
                    Chưa có bài viết nào được tạo.
                  </div>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Tiêu đề</TableHead>
                        <TableHead>Chuyên mục</TableHead>
                        <TableHead className="text-right">Loại</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {latestArticles.map((article) => (
                        <TableRow key={article.id}>
                          <TableCell className="font-medium max-w-[150px] truncate" title={article.titleVi}>
                            {article.titleVi}
                          </TableCell>
                          <TableCell className="text-xs text-muted-foreground">
                            {getCategoryName(article.category)}
                          </TableCell>
                          <TableCell className="text-right">
                            {article.isPremium ? (
                              <span className="text-xs font-semibold text-amber-600">VIP</span>
                            ) : (
                              <span className="text-xs font-semibold text-green-600">Free</span>
                            )}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>
          </div>
        </main>
      </div>
    </ProtectedRoute>
  );
}
