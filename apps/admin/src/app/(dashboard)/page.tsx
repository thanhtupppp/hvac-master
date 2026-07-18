"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Users, FileText, ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useArticles, useUserStats, useCategories } from "@/hooks";
import { getCategoryName } from "@/constants";
import { Skeleton } from "@/components/ui/skeleton";
import Link from "next/link";

export default function Dashboard() {
  const { articles: latestArticles, totalCount: articlesCount, isLoading: isArticlesLoading, error: articlesError } = useArticles(5);
  const { usersCount, vipCount, isLoading: isStatsLoading, error: statsError } = useUserStats();
  const { categoriesMap, error: categoriesError } = useCategories();

  return (
    <>
      <div className="flex items-center justify-between">
        <h2 className="text-3xl font-bold tracking-tight">Tổng quan</h2>
        <div className="flex items-center space-x-2">
          <Link href="/editor">
            <Button>Tạo bài viết mới</Button>
          </Link>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-3">
        {/* Card 1: Users Count */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tổng số người dùng</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent aria-busy={isStatsLoading} aria-live="polite">
            {statsError ? (
              <span className="text-sm font-medium text-red-500">Lỗi tải dữ liệu</span>
            ) : isStatsLoading ? (
              <>
                <Skeleton className="h-8 w-20" aria-hidden="true" />
                <span className="sr-only">Đang tải số lượng người dùng...</span>
              </>
            ) : (
              <div className="text-2xl font-bold">{usersCount}</div>
            )}
            <p className="text-xs text-muted-foreground mt-1">Đăng ký trong hệ thống</p>
          </CardContent>
        </Card>

        {/* Card 2: VIP Count */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Hội viên VIP (Premium)</CardTitle>
            <span className="text-amber-500 font-bold text-lg">★</span>
          </CardHeader>
          <CardContent aria-busy={isStatsLoading} aria-live="polite">
            {statsError ? (
              <span className="text-sm font-medium text-red-500">Lỗi tải dữ liệu</span>
            ) : isStatsLoading ? (
              <>
                <Skeleton className="h-8 w-20" aria-hidden="true" />
                <Skeleton className="h-3 w-32 mt-2" aria-hidden="true" />
                <span className="sr-only">Đang tải số lượng hội viên VIP...</span>
              </>
            ) : (
              <>
                <div className="text-2xl font-bold">{vipCount}</div>
                <p className="text-xs text-muted-foreground mt-1">
                  {usersCount > 0 ? `${Math.round((vipCount / usersCount) * 100)}% tổng số người dùng` : "0%"}
                </p>
              </>
            )}
          </CardContent>
        </Card>

        {/* Card 3: Articles Count */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tổng số bài viết</CardTitle>
            <FileText className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent aria-busy={isArticlesLoading} aria-live="polite">
            {articlesError ? (
              <span className="text-sm font-medium text-red-500">Lỗi tải dữ liệu</span>
            ) : isArticlesLoading ? (
              <>
                <Skeleton className="h-8 w-20" aria-hidden="true" />
                <span className="sr-only">Đang tải tổng số bài viết...</span>
              </>
            ) : (
              <div className="text-2xl font-bold">{articlesCount}</div>
            )}
            <p className="text-xs text-muted-foreground mt-1">Tài liệu và mã lỗi HVAC</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-7">
        {/* Card 4: System activity chart */}
        <Card className="col-span-4">
          <CardHeader>
            <CardTitle>Biểu đồ hoạt động hệ thống</CardTitle>
          </CardHeader>
          <CardContent className="h-[260px] flex items-center justify-center text-muted-foreground bg-muted/40 rounded-md m-4 mt-0">
            {/* TODO: Tích hợp chart hoạt động thật sự (recharts / Tremor) - JIRA-HVAC-104 */}
            <span>Biểu đồ hoạt động đang được phát triển</span>
          </CardContent>
        </Card>

        {/* Card 5: Latest Articles */}
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
            {articlesError ? (
              <div className="py-8 text-center text-red-500">
                Lỗi khi kết nối cơ sở dữ liệu bài viết.
              </div>
            ) : isArticlesLoading ? (
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
                  {latestArticles.map((article, index) => (
                    <TableRow key={article.id ?? `article-${index}`}>
                      <TableCell className="font-medium max-w-[150px] truncate" title={article.titleVi}>
                        {article.titleVi}
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">
                        {categoriesError ? "Lỗi tải mục" : getCategoryName(article.category, categoriesMap)}
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
    </>
  );
}
