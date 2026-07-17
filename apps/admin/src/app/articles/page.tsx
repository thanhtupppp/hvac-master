"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { 
  Plus, 
  Trash2, 
  FileText, 
  Pencil, 
  Search, 
  Filter, 
  Lock, 
  Unlock, 
  Layers, 
  Award, 
  Database,
  Building,
  Sparkles,
  Eye
} from "lucide-react";
import ProtectedRoute from "@/components/ProtectedRoute";
import Header from "@/components/Header";
import { db } from "@/lib/firebase";
import { collection, doc, deleteDoc, query, orderBy, onSnapshot } from "firebase/firestore";
import Link from "next/link";

interface Article {
  id: string;
  titleVi: string;
  category: string;
  brand: string;
  isPremium: boolean;
  createdAt?: any;
  views?: number;
}

export default function ArticlesPage() {
  const [articles, setArticles] = useState<Article[]>([]);
  const [categoriesMap, setCategoriesMap] = useState<Record<string, string>>({});
  const [brandsMap, setBrandsMap] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(true);

  // Search & Filter States
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [selectedBrand, setSelectedBrand] = useState("all");
  const [selectedType, setSelectedType] = useState("all");

  // Load categories
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

  // Load brands
  useEffect(() => {
    const q = query(collection(db, "brands"));
    const unsubscribeBrands = onSnapshot(q, (snapshot) => {
      const tempMap: Record<string, string> = {};
      snapshot.forEach((doc) => {
        tempMap[doc.id] = doc.data().name || doc.id;
      });
      setBrandsMap(tempMap);
    });

    return () => unsubscribeBrands();
  }, []);

  // Load articles
  useEffect(() => {
    const q = query(collection(db, "articles"), orderBy("createdAt", "desc"));
    const unsubscribeArticles = onSnapshot(q, (snapshot) => {
      const articlesList: Article[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        articlesList.push({
          id: doc.id,
          titleVi: data.title_vi || "",
          category: data.category || "",
          brand: data.brand || "",
          isPremium: data.isPremium || false,
          createdAt: data.createdAt,
          views: data.views || 0,
        });
      });
      setArticles(articlesList);
      setIsLoading(false);
    });

    return () => unsubscribeArticles();
  }, []);

  const handleDeleteArticle = async (articleId: string, articleTitle: string) => {
    if (!confirm(`Bạn có chắc chắn muốn xóa bài viết "${articleTitle}" không?`)) {
      return;
    }

    try {
      await deleteDoc(doc(db, "articles", articleId));
      alert("Đã xóa bài viết thành công!");
    } catch (error: any) {
      console.error(error);
      alert("Lỗi khi xóa bài viết: " + error.message);
    }
  };

  const getCategoryName = (catKey: string) => {
    const defaultMap: Record<string, string> = {
      ac: "Điều hòa",
      fridge: "Tủ lạnh",
      "washing-machine": "Máy giặt",
      microwave: "Lò vi sóng",
    };
    return categoriesMap[catKey] || defaultMap[catKey] || catKey;
  };

  const getBrandName = (brandKey: string) => {
    return brandsMap[brandKey] || brandKey || "—";
  };

  // Client-side filtering logic
  const filteredArticles = articles.filter((article) => {
    const titleMatch = article.titleVi.toLowerCase().includes(searchQuery.toLowerCase());
    const categoryMatch = selectedCategory === "all" || article.category === selectedCategory;
    const brandMatch = selectedBrand === "all" || article.brand === selectedBrand;
    const typeMatch = selectedType === "all" || 
      (selectedType === "premium" && article.isPremium) || 
      (selectedType === "free" && !article.isPremium);

    return titleMatch && categoryMatch && brandMatch && typeMatch;
  });

  // Calculate statistics
  const totalCount = articles.length;
  const premiumCount = articles.filter(a => a.isPremium).length;
  const freeCount = totalCount - premiumCount;
  const brandCount = new Set(articles.map(a => a.brand).filter(Boolean)).size;

  return (
    <ProtectedRoute>
      <div className="flex min-h-screen w-full flex-col bg-gray-50 dark:bg-gray-900">
        <Header />

        <main className="flex-1 space-y-6 p-8 max-w-[1600px] mx-auto w-full">
          {/* Header Title and Actions */}
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h2 className="text-3xl font-extrabold tracking-tight text-gray-900 dark:text-white">
                Quản lý Bài viết Hướng dẫn
              </h2>
              <p className="text-sm text-muted-foreground mt-1">
                Quản lý các quy trình chẩn đoán, nguyên nhân mã lỗi và dịch tài liệu kỹ thuật đa ngôn ngữ.
              </p>
            </div>
            <Link href="/editor">
              <Button className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold transition-all shadow-md shadow-blue-500/10">
                <Plus className="h-4.5 w-4.5" />
                Tạo bài viết mới
              </Button>
            </Link>
          </div>

          {/* Quick Statistics Cards */}
          <div className="grid gap-4 grid-cols-2 lg:grid-cols-4">
            <Card className="border-blue-100 dark:border-blue-900/20 bg-linear-to-br from-white to-blue-50/10 dark:from-gray-950 dark:to-blue-950/5">
              <CardContent className="p-5 flex items-center justify-between">
                <div>
                  <span className="text-xs text-muted-foreground font-semibold block uppercase tracking-wider">Tổng bài viết</span>
                  <span className="text-2xl font-bold text-gray-900 dark:text-white mt-1 block">{totalCount}</span>
                </div>
                <div className="h-10 w-10 rounded-lg bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 dark:text-blue-400">
                  <Database className="h-5 w-5" />
                </div>
              </CardContent>
            </Card>

            <Card className="border-amber-100 dark:border-amber-900/20 bg-linear-to-br from-white to-amber-50/10 dark:from-gray-950 dark:to-amber-950/5">
              <CardContent className="p-5 flex items-center justify-between">
                <div>
                  <span className="text-xs text-muted-foreground font-semibold block uppercase tracking-wider">Bài viết VIP (Premium)</span>
                  <span className="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-1 block">{premiumCount}</span>
                </div>
                <div className="h-10 w-10 rounded-lg bg-amber-50 dark:bg-amber-900/30 flex items-center justify-center text-amber-600 dark:text-amber-400">
                  <Award className="h-5 w-5" />
                </div>
              </CardContent>
            </Card>

            <Card className="border-emerald-100 dark:border-emerald-900/20 bg-linear-to-br from-white to-emerald-50/10 dark:from-gray-950 dark:to-emerald-950/5">
              <CardContent className="p-5 flex items-center justify-between">
                <div>
                  <span className="text-xs text-muted-foreground font-semibold block uppercase tracking-wider">Bài viết Miễn phí</span>
                  <span className="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1 block">{freeCount}</span>
                </div>
                <div className="h-10 w-10 rounded-lg bg-emerald-50 dark:bg-emerald-900/30 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
                  <Sparkles className="h-5 w-5" />
                </div>
              </CardContent>
            </Card>

            <Card className="border-indigo-100 dark:border-indigo-900/20 bg-linear-to-br from-white to-indigo-50/10 dark:from-gray-950 dark:to-indigo-950/5">
              <CardContent className="p-5 flex items-center justify-between">
                <div>
                  <span className="text-xs text-muted-foreground font-semibold block uppercase tracking-wider">Hãng sản xuất</span>
                  <span className="text-2xl font-bold text-indigo-600 dark:text-indigo-400 mt-1 block">{brandCount}</span>
                </div>
                <div className="h-10 w-10 rounded-lg bg-indigo-50 dark:bg-indigo-900/30 flex items-center justify-center text-indigo-600 dark:text-indigo-400">
                  <Building className="h-5 w-5" />
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Search, Filter and Main List */}
          <Card className="shadow-md">
            <CardHeader className="pb-3 border-b border-gray-100 dark:border-gray-800">
              <CardTitle className="text-lg font-bold flex items-center gap-2">
                <FileText className="h-5 w-5 text-blue-600" />
                Quản lý kho dữ liệu bài viết
              </CardTitle>
            </CardHeader>
            <CardContent className="pt-6 space-y-4">
              {/* Dynamic Filtering Row */}
              <div className="flex flex-col md:flex-row gap-3">
                {/* Search Field */}
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
                  <Input
                    placeholder="Tìm kiếm theo tiêu đề bài viết..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="pl-9 bg-white dark:bg-gray-950 border-gray-200 dark:border-gray-800"
                  />
                </div>

                {/* Category Filter */}
                <div className="w-full md:w-[180px]">
                  <Select value={selectedCategory} onValueChange={(val) => setSelectedCategory(val || "all")}>
                    <SelectTrigger className="bg-white dark:bg-gray-950 border-gray-200 dark:border-gray-800">
                      <span className="flex items-center gap-2 truncate">
                        <Layers className="h-3.5 w-3.5 text-blue-500 shrink-0" />
                        <SelectValue placeholder="Chuyên mục" />
                      </span>
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">Tất cả chuyên mục</SelectItem>
                      {Object.entries(categoriesMap).map(([key, name]) => (
                        <SelectItem key={key} value={key}>{name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Brand Filter */}
                <div className="w-full md:w-[180px]">
                  <Select value={selectedBrand} onValueChange={(val) => setSelectedBrand(val || "all")}>
                    <SelectTrigger className="bg-white dark:bg-gray-950 border-gray-200 dark:border-gray-800">
                      <span className="flex items-center gap-2 truncate">
                        <Building className="h-3.5 w-3.5 text-indigo-500 shrink-0" />
                        <SelectValue placeholder="Hãng sản xuất" />
                      </span>
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">Tất cả hãng sản xuất</SelectItem>
                      {Object.entries(brandsMap).map(([key, name]) => (
                        <SelectItem key={key} value={key}>{name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {/* Access Level Filter */}
                <div className="w-full md:w-[160px]">
                  <Select value={selectedType} onValueChange={(val) => setSelectedType(val || "all")}>
                    <SelectTrigger className="bg-white dark:bg-gray-950 border-gray-200 dark:border-gray-800">
                      <span className="flex items-center gap-2 truncate">
                        <Award className="h-3.5 w-3.5 text-amber-500 shrink-0" />
                        <SelectValue placeholder="Phân loại" />
                      </span>
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">Tất cả cấp độ</SelectItem>
                      <SelectItem value="free">Miễn phí</SelectItem>
                      <SelectItem value="premium">Premium (VIP)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Data Table */}
              {isLoading ? (
                <div className="py-20 text-center text-muted-foreground animate-pulse flex flex-col items-center justify-center gap-2">
                  <Database className="h-8 w-8 text-blue-500 animate-spin" />
                  <span>Đang tải danh sách bài viết từ Firestore...</span>
                </div>
              ) : filteredArticles.length === 0 ? (
                <div className="py-16 text-center text-muted-foreground border-2 border-dashed rounded-lg bg-gray-50/50 dark:bg-gray-950/20">
                  <FileText className="h-10 w-10 mx-auto text-muted-foreground/50 mb-3" />
                  <p className="font-semibold text-sm">Không tìm thấy bài viết nào phù hợp</p>
                  <p className="text-xs text-muted-foreground mt-1">Vui lòng kiểm tra lại bộ lọc hoặc tạo bài viết mới.</p>
                </div>
              ) : (
                <div className="border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-gray-950">
                  <Table>
                    <TableHeader className="bg-gray-50 dark:bg-gray-900/50">
                      <TableRow>
                        <TableHead className="font-semibold text-gray-700 dark:text-gray-300">Tiêu đề bài viết (Tiếng Việt)</TableHead>
                        <TableHead className="font-semibold text-gray-700 dark:text-gray-300">Chuyên mục</TableHead>
                        <TableHead className="font-semibold text-gray-700 dark:text-gray-300">Hãng sản xuất</TableHead>
                        <TableHead className="font-semibold text-gray-700 dark:text-gray-300">Phân loại</TableHead>
                        <TableHead className="font-semibold text-gray-700 dark:text-gray-300">Lượt xem</TableHead>
                        <TableHead className="w-[120px] text-right font-semibold text-gray-700 dark:text-gray-300">Thao tác</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredArticles.map((article) => (
                        <TableRow key={article.id} className="hover:bg-slate-50/40 dark:hover:bg-slate-900/25 transition-colors">
                          <TableCell className="font-medium max-w-md">
                            <Link 
                              href={`/editor?id=${article.id}`} 
                              className="text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400 hover:underline transition-colors font-semibold block py-1 cursor-pointer"
                              title="Bấm vào đây để chỉnh sửa bài viết"
                            >
                              {article.titleVi}
                            </Link>
                          </TableCell>
                          <TableCell>
                            <span className="inline-flex items-center rounded-full bg-blue-50 text-blue-700 dark:bg-blue-950/30 dark:text-blue-400 px-2.5 py-0.5 text-xs font-medium">
                              {getCategoryName(article.category)}
                            </span>
                          </TableCell>
                          <TableCell>
                            <span className="inline-flex items-center rounded-full bg-indigo-50 text-indigo-700 dark:bg-indigo-950/30 dark:text-indigo-400 px-2.5 py-0.5 text-xs font-medium">
                              {getBrandName(article.brand)}
                            </span>
                          </TableCell>
                          <TableCell>
                            {article.isPremium ? (
                              <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 text-amber-700 dark:bg-amber-950/30 dark:text-amber-400 px-2.5 py-0.5 text-xs font-bold border border-amber-200/30">
                                <Lock className="h-3 w-3 shrink-0" />
                                Premium (VIP)
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 text-emerald-700 dark:bg-emerald-950/30 dark:text-emerald-400 px-2.5 py-0.5 text-xs font-medium border border-emerald-200/30">
                                <Unlock className="h-3 w-3 shrink-0" />
                                Miễn phí
                              </span>
                            )}
                          </TableCell>
                          <TableCell>
                            <span className="inline-flex items-center gap-1.5 text-sm text-gray-600 dark:text-gray-400 font-medium">
                              <Eye className="h-4 w-4 text-gray-400 shrink-0" />
                              {article.views?.toLocaleString() || 0}
                            </span>
                          </TableCell>
                          <TableCell className="text-right">
                            <div className="flex justify-end gap-1">
                              <Link href={`/editor?id=${article.id}`}>
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  className="h-8 w-8 text-blue-500 hover:text-blue-700 hover:bg-blue-50 dark:hover:bg-blue-950/30"
                                  title="Chỉnh sửa bài viết"
                                >
                                  <Pencil className="h-4 w-4" />
                                </Button>
                              </Link>
                              <Button
                                variant="ghost"
                                size="icon"
                                onClick={() => handleDeleteArticle(article.id, article.titleVi)}
                                className="h-8 w-8 text-red-500 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-950/30"
                                title="Xóa bài viết"
                              >
                                <Trash2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              )}
            </CardContent>
          </Card>
        </main>
      </div>
    </ProtectedRoute>
  );
}
