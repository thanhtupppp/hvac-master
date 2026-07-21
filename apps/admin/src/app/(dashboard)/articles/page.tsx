"use client";

import { useState, useEffect, useRef, useMemo } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button, buttonVariants } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Plus,
  Trash2,
  FileText,
  Pencil,
  Search,
  Lock,
  Unlock,
  Layers,
  Award,
  Database,
  Building,
  Sparkles,
  Eye,
  AlertCircle,
  CheckCircle2,
} from "lucide-react";
import { useArticles, useCategories, useBrands } from "@/hooks";
import { getCategoryName } from "@/constants";
import { removeArticle } from "@/services/articles";
import Link from "next/link";
import { cn } from "@/lib/utils";

function getErrorMessage(error: unknown) {
  if (error instanceof Error) return error.message;
  return "Đã có lỗi không xác định xảy ra.";
}

export default function ArticlesPage() {
  const { articles, isLoading } = useArticles();
  const { categoriesMap } = useCategories();
  const { brandsMap } = useBrands();

  // Search & Filter States
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [selectedBrand, setSelectedBrand] = useState("all");
  const [selectedType, setSelectedType] = useState("all");

  const [deletingId, setDeletingId] = useState<string | null>(null);

  // Global feedback messages
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Custom Delete Confirm Dialog state
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);
  const [confirmDeleteTitle, setConfirmDeleteTitle] = useState<string | null>(
    null,
  );

  // Accessibility Refs for Modal Focus Management
  const headingRef = useRef<HTMLHeadingElement | null>(null);
  const cancelButtonRef = useRef<HTMLButtonElement | null>(null);
  const lastTriggerRef = useRef<HTMLButtonElement | null>(null);
  const wasDialogOpenRef = useRef(false);

  // 1. Accessibility: Modal Keydown Event Handler & Focus Trap
  useEffect(() => {
    if (!confirmDeleteId) return;

    // Shift focus into the cancel button when the modal opens
    requestAnimationFrame(() => {
      cancelButtonRef.current?.focus();
    });

    const handleKeyDown = (e: KeyboardEvent) => {
      // Escape key closes the modal
      if (e.key === "Escape" && deletingId === null) {
        setConfirmDeleteId(null);
        setConfirmDeleteTitle(null);
        return;
      }

      // Tab key keeps focus trapped inside the modal container
      if (e.key === "Tab") {
        const modalElement = document.getElementById("confirm-delete-modal");
        if (!modalElement) return;

        const focusableElements = modalElement.querySelectorAll(
          'button, [href], input, select, textarea, [tabindex="0"]',
        );
        if (focusableElements.length === 0) return;

        const firstElement = focusableElements[0] as HTMLElement;
        const lastElement = focusableElements[
          focusableElements.length - 1
        ] as HTMLElement;

        if (e.shiftKey) {
          if (document.activeElement === firstElement) {
            lastElement.focus();
            e.preventDefault();
          }
        } else {
          if (document.activeElement === lastElement) {
            firstElement.focus();
            e.preventDefault();
          }
        }
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [confirmDeleteId, deletingId]);

  // 2. Accessibility: Return focus back to the original delete button that triggered the modal,
  // or fallback to the page heading if the button is no longer in the DOM (e.g. after deletion).
  useEffect(() => {
    if (confirmDeleteId) {
      wasDialogOpenRef.current = true;
      return;
    }

    if (!wasDialogOpenRef.current) return;

    if (lastTriggerRef.current && lastTriggerRef.current.isConnected) {
      lastTriggerRef.current.focus();
    } else if (headingRef.current) {
      headingRef.current.focus();
    }

    wasDialogOpenRef.current = false;
  }, [confirmDeleteId]);

  const handleOpenConfirmDelete = (
    articleId: string,
    articleTitle: string,
    trigger: HTMLButtonElement | null,
  ) => {
    lastTriggerRef.current = trigger;
    setConfirmDeleteId(articleId);
    setConfirmDeleteTitle(articleTitle);
    setErrorMsg(null);
    setSuccessMsg(null);
  };

  const handleExecuteDelete = async () => {
    if (!confirmDeleteId) return;

    const articleId = confirmDeleteId;
    const articleTitle = confirmDeleteTitle || "";

    setConfirmDeleteId(null);
    setConfirmDeleteTitle(null);
    setDeletingId(articleId);

    try {
      await removeArticle(articleId);
      setSuccessMsg(`Đã xóa bài viết "${articleTitle}" thành công!`);
    } catch (error) {
      console.error(error);
      setErrorMsg("Lỗi khi xóa bài viết: " + getErrorMessage(error));
    } finally {
      setDeletingId(null);
    }
  };

  const getBrandName = (brandKey: string) => {
    return brandsMap[brandKey] || brandKey || "—";
  };

  // Client-side filtering logic
  const filteredArticles = useMemo(() => {
    return articles.filter((article) => {
      const titleMatch = article.titleVi
        .toLowerCase()
        .includes(searchQuery.toLowerCase());
      const categoryMatch =
        selectedCategory === "all" || article.category === selectedCategory;
      const brandMatch =
        selectedBrand === "all" || article.brand === selectedBrand;
      const typeMatch =
        selectedType === "all" ||
        (selectedType === "premium" && article.isPremium) ||
        (selectedType === "free" && !article.isPremium);
      return titleMatch && categoryMatch && brandMatch && typeMatch;
    });
  }, [articles, searchQuery, selectedCategory, selectedBrand, selectedType]);

  // Calculate statistics
  const totalCount = articles.length;
  const premiumCount = useMemo(
    () => articles.filter((a) => a.isPremium).length,
    [articles],
  );
  const freeCount = totalCount - premiumCount;
  const brandCount = useMemo(
    () => new Set(articles.flatMap((a) => (a.brand ? [a.brand] : []))).size,
    [articles],
  );

  return (
    <>
      {/* Header Title and Actions */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2
            ref={headingRef}
            tabIndex={-1}
            className="text-3xl font-extrabold tracking-tight text-gray-900 dark:text-white focus:outline-none"
          >
            Quản lý Bài viết Hướng dẫn
          </h2>
          <p className="text-sm text-muted-foreground mt-1">
            Quản lý các quy trình chẩn đoán, nguyên nhân mã lỗi và dịch tài liệu
            kỹ thuật đa ngôn ngữ.
          </p>
        </div>
        <Link
          href="/editor"
          className={cn(
            buttonVariants(),
            "flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white font-semibold transition-all shadow-md shadow-blue-500/10",
          )}
        >
          <Plus className="h-4.5 w-4.5" />
          Tạo bài viết mới
        </Link>
      </div>

      {/* Screen Reader Only Announcements (Permanent Live Regions in Accessibility Tree) */}
      <div className="sr-only" aria-live="polite" aria-atomic="true">
        {errorMsg ? `Lỗi: ${errorMsg}` : ""}
      </div>
      <div className="sr-only" aria-live="polite" aria-atomic="true">
        {successMsg ? `Thông báo: ${successMsg}` : ""}
      </div>

      {/* Visual Alerts (Not live regions, purely visual box presentation) */}
      <div className="space-y-2 max-w-3xl my-4">
        {errorMsg && (
          <div className="flex items-start gap-2 text-sm font-medium text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-950/20 p-3 rounded border border-red-200 dark:border-red-900/30 animate-in fade-in slide-in-from-top-1 duration-200">
            <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
            <span>{errorMsg}</span>
          </div>
        )}

        {successMsg && (
          <div className="flex items-start gap-2 text-sm font-medium text-green-600 dark:text-green-400 bg-green-50 dark:bg-green-950/20 p-3 rounded border border-green-200 dark:border-green-900/30 animate-in fade-in slide-in-from-top-1 duration-200">
            <CheckCircle2 className="h-4 w-4 shrink-0 mt-0.5" />
            <span>{successMsg}</span>
          </div>
        )}
      </div>

      {/* Quick Statistics Cards */}
      <div className="grid gap-4 grid-cols-2 lg:grid-cols-4">
        <Card className="border-blue-100 dark:border-blue-900/20 bg-linear-to-br from-white to-blue-50/10 dark:from-gray-950 dark:to-blue-950/5">
          <CardContent className="p-5 flex items-center justify-between">
            <div>
              <span className="text-xs text-muted-foreground font-semibold block uppercase tracking-wider">
                Tổng bài viết
              </span>
              <span className="text-2xl font-bold text-gray-900 dark:text-white mt-1 block">
                {totalCount}
              </span>
            </div>
            <div className="h-10 w-10 rounded-lg bg-blue-50 dark:bg-blue-900/30 flex items-center justify-center text-blue-600 dark:text-blue-400">
              <Database className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-amber-100 dark:border-amber-900/20 bg-linear-to-br from-white to-amber-50/10 dark:from-gray-950 dark:to-amber-950/5">
          <CardContent className="p-5 flex items-center justify-between">
            <div>
              <span className="text-xs text-muted-foreground font-semibold block uppercase tracking-wider">
                Bài viết VIP (Premium)
              </span>
              <span className="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-1 block">
                {premiumCount}
              </span>
            </div>
            <div className="h-10 w-10 rounded-lg bg-amber-50 dark:bg-amber-900/30 flex items-center justify-center text-amber-600 dark:text-amber-400">
              <Award className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-emerald-100 dark:border-emerald-900/20 bg-linear-to-br from-white to-emerald-50/10 dark:from-gray-950 dark:to-emerald-950/5">
          <CardContent className="p-5 flex items-center justify-between">
            <div>
              <span className="text-xs text-muted-foreground font-semibold block uppercase tracking-wider">
                Bài viết Miễn phí
              </span>
              <span className="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1 block">
                {freeCount}
              </span>
            </div>
            <div className="h-10 w-10 rounded-lg bg-emerald-50 dark:bg-emerald-900/30 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
              <Sparkles className="h-5 w-5" />
            </div>
          </CardContent>
        </Card>

        <Card className="border-indigo-100 dark:border-indigo-900/20 bg-linear-to-br from-white to-indigo-50/10 dark:from-gray-950 dark:to-indigo-950/5">
          <CardContent className="p-5 flex items-center justify-between">
            <div>
              <span className="text-xs text-muted-foreground font-semibold block uppercase tracking-wider">
                Hãng sản xuất
              </span>
              <span className="text-2xl font-bold text-indigo-600 dark:text-indigo-400 mt-1 block">
                {brandCount}
              </span>
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
            <div className="relative flex-1">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Tìm kiếm theo tiêu đề bài viết..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9 bg-white dark:bg-gray-950 border-gray-200 dark:border-gray-800"
              />
            </div>
            <div className="w-full md:w-45">
              <Select
                value={selectedCategory}
                onValueChange={(val) => setSelectedCategory(val || "all")}
              >
                <SelectTrigger className="bg-white dark:bg-gray-950 border-gray-200 dark:border-gray-800">
                  <span className="flex items-center gap-2 truncate">
                    <Layers className="h-3.5 w-3.5 text-blue-500 shrink-0" />
                    <SelectValue placeholder="Chuyên mục" />
                  </span>
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tất cả chuyên mục</SelectItem>
                  {Object.entries(categoriesMap).map(([key, name]) => (
                    <SelectItem key={key} value={key}>
                      {name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="w-full md:w-45">
              <Select
                value={selectedBrand}
                onValueChange={(val) => setSelectedBrand(val || "all")}
              >
                <SelectTrigger className="bg-white dark:bg-gray-950 border-gray-200 dark:border-gray-800">
                  <span className="flex items-center gap-2 truncate">
                    <Building className="h-3.5 w-3.5 text-indigo-500 shrink-0" />
                    <SelectValue placeholder="Hãng sản xuất" />
                  </span>
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Tất cả hãng sản xuất</SelectItem>
                  {Object.entries(brandsMap).map(([key, name]) => (
                    <SelectItem key={key} value={key}>
                      {name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="w-full md:w-40">
              <Select
                value={selectedType}
                onValueChange={(val) => setSelectedType(val || "all")}
              >
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
              <p className="font-semibold text-sm">
                Không tìm thấy bài viết nào phù hợp
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                Vui lòng kiểm tra lại bộ lọc hoặc tạo bài viết mới.
              </p>
            </div>
          ) : (
            <div className="border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-gray-950">
              <Table>
                <TableHeader className="bg-gray-50 dark:bg-gray-900/50">
                  <TableRow>
                    <TableHead className="font-semibold text-gray-700 dark:text-gray-300">
                      Tiêu đề bài viết (Tiếng Việt)
                    </TableHead>
                    <TableHead className="font-semibold text-gray-700 dark:text-gray-300">
                      Chuyên mục
                    </TableHead>
                    <TableHead className="font-semibold text-gray-700 dark:text-gray-300">
                      Hãng sản xuất
                    </TableHead>
                    <TableHead className="font-semibold text-gray-700 dark:text-gray-300">
                      Phân loại
                    </TableHead>
                    <TableHead className="font-semibold text-gray-700 dark:text-gray-300">
                      Lượt xem
                    </TableHead>
                    <TableHead className="w-30 text-right font-semibold text-gray-700 dark:text-gray-300">
                      Thao tác
                    </TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredArticles.map((article) => (
                    <TableRow
                      key={article.id}
                      className="hover:bg-slate-50/40 dark:hover:bg-slate-900/25 transition-colors"
                    >
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
                          {getCategoryName(article.category, categoriesMap)}
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
                          <Link
                            href={`/editor?id=${article.id}`}
                            aria-label={`Chỉnh sửa bài viết ${article.titleVi}`}
                            title={`Chỉnh sửa bài viết ${article.titleVi}`}
                            className={cn(
                              buttonVariants({
                                variant: "ghost",
                                size: "icon",
                              }),
                              "h-8 w-8 text-blue-500 hover:text-blue-700 hover:bg-blue-50 dark:hover:bg-blue-950/30",
                              deletingId !== null &&
                                "pointer-events-none opacity-50",
                            )}
                          >
                            <Pencil className="h-4 w-4" aria-hidden="true" />
                          </Link>
                          <Button
                            variant="ghost"
                            size="icon"
                            disabled={deletingId !== null}
                            onClick={(e) =>
                              handleOpenConfirmDelete(
                                article.id,
                                article.titleVi,
                                e.currentTarget,
                              )
                            }
                            className="h-8 w-8 text-red-500 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-950/30"
                            aria-label={`Xóa bài viết ${article.titleVi}`}
                            title={`Xóa bài viết ${article.titleVi}`}
                          >
                            <Trash2 className="h-4 w-4" aria-hidden="true" />
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

      {/* Accessible Custom Confirm Delete Modal Overlay */}
      {confirmDeleteId && (
        <div
          id="confirm-delete-modal"
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm animate-in fade-in duration-200"
          role="alertdialog"
          aria-modal="true"
          aria-labelledby="confirm-modal-title"
          aria-describedby="confirm-modal-description"
        >
          <div className="bg-background border rounded-lg max-w-md w-full p-6 shadow-xl animate-in zoom-in-95 duration-200 mx-4">
            <h3
              id="confirm-modal-title"
              className="text-lg font-bold text-foreground mb-2"
            >
              Xác nhận xóa bài viết
            </h3>
            <p
              id="confirm-modal-description"
              className="text-sm text-muted-foreground mb-6"
            >
              Bạn có chắc chắn muốn xóa bài viết{" "}
              <span className="font-semibold text-foreground">
                "{confirmDeleteTitle}"
              </span>
              ? Hành động này sẽ loại bỏ hoàn toàn tài liệu này và không thể
              hoàn tác.
            </p>
            <div className="flex justify-end gap-3">
              <Button
                ref={cancelButtonRef}
                variant="outline"
                type="button"
                onClick={() => {
                  setConfirmDeleteId(null);
                  setConfirmDeleteTitle(null);
                }}
                disabled={deletingId !== null}
              >
                Hủy
              </Button>
              <Button
                variant="destructive"
                type="button"
                onClick={handleExecuteDelete}
                disabled={deletingId !== null}
              >
                {deletingId ? "Đang xóa..." : "Xóa bài viết"}
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
