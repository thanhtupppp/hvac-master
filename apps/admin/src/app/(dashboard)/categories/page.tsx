"use client";

import { useMemo, useState, useEffect, useRef } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Plus, Trash2, FolderOpen, AlertCircle, CheckCircle2 } from "lucide-react";
import { useCategories } from "@/hooks";
import { createCategory, removeCategory } from "@/services/categories";

function normalizeSlug(value: string) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-{2,}/g, "-");
}

function getErrorMessage(error: unknown) {
  if (error instanceof Error) return error.message;
  return "Đã có lỗi không xác định xảy ra.";
}

export default function CategoriesPage() {
  const { categories, isLoading } = useCategories();

  const [slug, setSlug] = useState("");
  const [name, setName] = useState("");
  const [isSaving, setIsSaving] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  // Field-level error messages
  const [slugError, setSlugError] = useState<string | null>(null);
  const [nameError, setNameError] = useState<string | null>(null);

  // Global feedback messages
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Custom Delete Confirm Dialog state
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);
  const [confirmDeleteName, setConfirmDeleteName] = useState<string | null>(null);

  // Accessibility Refs for Modal Focus Management
  const headingRef = useRef<HTMLHeadingElement | null>(null);
  const cancelButtonRef = useRef<HTMLButtonElement | null>(null);
  const lastTriggerRef = useRef<HTMLButtonElement | null>(null);
  const wasDialogOpenRef = useRef(false);

  const cleanedSlug = useMemo(() => normalizeSlug(slug), [slug]);
  const cleanedName = useMemo(() => name.trim(), [name]);

  const canSubmit = cleanedSlug.length > 0 && cleanedName.length > 0 && !isSaving && deletingId === null;

  // 1. Accessibility: Modal Keydown Event Handler & Focus Trap
  useEffect(() => {
    if (!confirmDeleteId) return;

    // Shift focus into the cancel button when the modal opens
    // Using requestAnimationFrame to ensure the DOM elements are mounted and painted
    requestAnimationFrame(() => {
      cancelButtonRef.current?.focus();
    });

    const handleKeyDown = (e: KeyboardEvent) => {
      // Escape key closes the modal
      if (e.key === "Escape" && deletingId === null) {
        setConfirmDeleteId(null);
        setConfirmDeleteName(null);
        return;
      }

      // Tab key keeps focus trapped inside the modal container
      if (e.key === "Tab") {
        const modalElement = document.getElementById("confirm-delete-modal");
        if (!modalElement) return;

        const focusableElements = modalElement.querySelectorAll(
          'button, [href], input, select, textarea, [tabindex="0"]'
        );
        if (focusableElements.length === 0) return;

        const firstElement = focusableElements[0] as HTMLElement;
        const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;

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

  const handleSlugChange = (val: string) => {
    setSlug(val);
    if (slugError) setSlugError(null);
    if (errorMsg) setErrorMsg(null);
  };

  const handleNameChange = (val: string) => {
    setName(val);
    if (nameError) setNameError(null);
    if (errorMsg) setErrorMsg(null);
  };

  const handleAddCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setSuccessMsg(null);
    setSlugError(null);
    setNameError(null);

    let hasError = false;
    if (!cleanedSlug) {
      setSlugError("Mã chuyên mục (Slug ID) không được để trống.");
      hasError = true;
    }
    if (!cleanedName) {
      setNameError("Tên chuyên mục hiển thị không được để trống.");
      hasError = true;
    }

    if (hasError) return;

    setIsSaving(true);
    try {
      await createCategory(cleanedSlug, cleanedName);
      setSlug("");
      setName("");
      setSuccessMsg("Thêm chuyên mục thành công!");
    } catch (error) {
      console.error(error);
      setErrorMsg("Lỗi khi thêm chuyên mục: " + getErrorMessage(error));
    } finally {
      setIsSaving(false);
    }
  };

  const handleOpenConfirmDelete = (catId: string, catName: string, trigger: HTMLButtonElement | null) => {
    lastTriggerRef.current = trigger;
    setConfirmDeleteId(catId);
    setConfirmDeleteName(catName);
    setErrorMsg(null);
    setSuccessMsg(null);
  };

  const handleExecuteDelete = async () => {
    if (!confirmDeleteId) return;

    const catId = confirmDeleteId;
    const catName = confirmDeleteName || "";

    setConfirmDeleteId(null);
    setConfirmDeleteName(null);
    setDeletingId(catId);

    try {
      await removeCategory(catId);
      setSuccessMsg(`Đã xóa chuyên mục "${catName}" thành công!`);
    } catch (error) {
      console.error(error);
      setErrorMsg("Lỗi khi xóa chuyên mục: " + getErrorMessage(error));
    } finally {
      setDeletingId(null);
    }
  };

  return (
    <>
      <div className="flex items-center justify-between">
        <h2 
          ref={headingRef} 
          tabIndex={-1} 
          className="text-3xl font-bold tracking-tight focus:outline-none"
        >
          Quản lý chuyên mục
        </h2>
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

      <div className="grid gap-6 md:grid-cols-3">
        <Card className="md:col-span-1 h-fit">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <Plus className="h-5 w-5 text-blue-600 animate-in fade-in" />
              Thêm chuyên mục mới
            </CardTitle>
          </CardHeader>

          <CardContent>
            <form onSubmit={handleAddCategory} className="space-y-4" noValidate>
              <div className="space-y-2">
                <Label htmlFor="slug">Mã chuyên mục (Slug ID)</Label>
                <Input
                  id="slug"
                  placeholder="Ví dụ: washing-machine, ac"
                  value={slug}
                  onChange={(e) => handleSlugChange(e.target.value)}
                  className={slugError ? "border-red-500 focus-visible:ring-red-500" : ""}
                  aria-invalid={slugError ? "true" : "false"}
                  aria-describedby={slugError ? "slug-error" : undefined}
                  disabled={isSaving || deletingId !== null}
                />
                {slugError ? (
                  <p id="slug-error" className="text-xs font-semibold text-red-500 mt-1 flex items-center gap-1" role="alert">
                    <AlertCircle className="h-3 w-3" /> {slugError}
                  </p>
                ) : (
                  <p className="text-xs text-muted-foreground">
                    Slug chuẩn hóa: <span className="font-mono font-semibold text-blue-600 dark:text-blue-400">{cleanedSlug || "..."}</span>
                  </p>
                )}
              </div>

              <div className="space-y-2">
                <Label htmlFor="name">Tên chuyên mục hiển thị</Label>
                <Input
                  id="name"
                  placeholder="Ví dụ: Máy giặt, Điều hòa"
                  value={name}
                  onChange={(e) => handleNameChange(e.target.value)}
                  className={nameError ? "border-red-500 focus-visible:ring-red-500" : ""}
                  aria-invalid={nameError ? "true" : "false"}
                  aria-describedby={nameError ? "name-error" : undefined}
                  disabled={isSaving || deletingId !== null}
                />
                {nameError && (
                  <p id="name-error" className="text-xs font-semibold text-red-500 mt-1 flex items-center gap-1" role="alert">
                    <AlertCircle className="h-3 w-3" /> {nameError}
                  </p>
                )}
              </div>

              <Button type="submit" className="w-full" disabled={!canSubmit}>
                {isSaving ? "Đang lưu..." : "Thêm chuyên mục"}
              </Button>
            </form>
          </CardContent>
        </Card>

        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-lg">
              <FolderOpen className="h-5 w-5 text-blue-600" />
              Danh sách chuyên mục đang có
            </CardTitle>
          </CardHeader>

          <CardContent>
            {isLoading ? (
              <div className="py-8 text-center text-muted-foreground animate-pulse">
                Đang tải dữ liệu từ Firestore...
              </div>
            ) : categories.length === 0 ? (
              <div className="py-8 text-center text-muted-foreground">
                Chưa có chuyên mục nào được tạo.
              </div>
            ) : (
              <div className="rounded-md border">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Mã (Slug ID)</TableHead>
                      <TableHead>Tên chuyên mục</TableHead>
                      <TableHead className="w-[100px] text-right">Thao tác</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {categories.map((cat) => (
                      <TableRow key={cat.id}>
                        <TableCell className="font-mono text-sm text-blue-600 dark:text-blue-400">
                          {cat.id}
                        </TableCell>
                        <TableCell className="font-medium">{cat.name}</TableCell>
                        <TableCell className="text-right">
                          <Button
                            variant="ghost"
                            size="icon"
                            type="button"
                            disabled={deletingId !== null || isSaving}
                            onClick={(e) => handleOpenConfirmDelete(cat.id, cat.name, e.currentTarget)}
                            aria-label={`Xóa chuyên mục ${cat.name}`}
                            title={`Xóa chuyên mục ${cat.name}`}
                          >
                            <Trash2 className="h-4 w-4 text-red-500 hover:text-red-700" aria-hidden="true" />
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

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
            <h3 id="confirm-modal-title" className="text-lg font-bold text-foreground mb-2">
              Xác nhận xóa chuyên mục
            </h3>
            <p id="confirm-modal-description" className="text-sm text-muted-foreground mb-6">
              Bạn có chắc chắn muốn xóa chuyên mục <span className="font-semibold text-foreground">"{confirmDeleteName}"</span>? Hành động này sẽ loại bỏ hoàn toàn danh mục này và không thể hoàn tác.
            </p>
            <div className="flex justify-end gap-3">
              <Button 
                ref={cancelButtonRef}
                variant="outline" 
                type="button"
                onClick={() => { setConfirmDeleteId(null); setConfirmDeleteName(null); }}
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
                {deletingId ? "Đang xóa..." : "Xóa chuyên mục"}
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
