"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { usePlans } from "@/hooks";
import type {
  SubscriptionPlan,
  PlanInterval,
  PlanProvider,
  PlanStats,
} from "@/types";
import {
  Plus,
  Pencil,
  Trash2,
  Eye,
  EyeOff,
  Star,
  StarOff,
  Package,
  CheckCircle2,
  XCircle,
  RefreshCw,
  ChevronDown,
  ChevronUp,
} from "lucide-react";

const INTERVAL_LABELS: Record<PlanInterval, string> = {
  monthly: "Hàng tháng",
  quarterly: "Hàng quý",
  yearly: "Hàng năm",
  lifetime: "Trọn đời",
};

const PROVIDER_LABELS: Record<PlanProvider, string> = {
  google_play: "Google Play",
  app_store: "App Store",
  web: "Web",
};

const THEME_COLORS: Record<string, string> = {
  blue: "bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-200",
  purple:
    "bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-200",
  gold: "bg-amber-100 text-amber-700 dark:bg-amber-900 dark:text-amber-200",
};

const plansVndFormatter = new Intl.NumberFormat("vi-VN", {
  style: "currency",
  currency: "VND",
  maximumFractionDigits: 0,
});

function formatVND(n: number) {
  if (!n) return "—";
  return plansVndFormatter.format(n);
}

export default function PlansPage() {
  const {
    plans,
    total,
    isLoading,
    error,
    refetch,
    createPlan,
    updatePlan,
    deletePlan,
    toggleActive,
  } = usePlans();
  const [editing, setEditing] = useState<SubscriptionPlan | null>(null);
  const [showModal, setShowModal] = useState(false);

  const stats: PlanStats = computeStats(plans);

  const openCreate = () => {
    setEditing(null);
    setShowModal(true);
  };
  const openEdit = (plan: SubscriptionPlan) => {
    setEditing(plan);
    setShowModal(true);
  };
  const closeModal = () => {
    setEditing(null);
    setShowModal(false);
  };

  const handleSave = async (data: any) => {
    try {
      if (editing) {
        await updatePlan(editing.id, data);
      } else {
        await createPlan(data);
      }
      closeModal();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleDelete = async (id: string) => {
    try {
      await deletePlan(id);
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleToggleActive = async (id: string, isActive: boolean) => {
    try {
      await toggleActive(id, !isActive);
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleToggleFeatured = async (plan: SubscriptionPlan) => {
    try {
      await updatePlan(plan.id, { isFeatured: !plan.isFeatured });
    } catch (err: any) {
      alert(err.message);
    }
  };

  const moveSort = async (plan: SubscriptionPlan, delta: number) => {
    try {
      await updatePlan(plan.id, { sortOrder: plan.sortOrder + delta });
    } catch (err: any) {
      alert(err.message);
    }
  };

  return (
    <>
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">
            Quản lý gói thanh toán
          </h2>
          <p className="text-sm text-muted-foreground mt-1">
            Cấu hình các gói VIP hiển thị trên paywall mobile. Thay đổi áp dụng
            sau ~5 phút (cache CDN).
          </p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={refetch}
            disabled={isLoading}
          >
            <RefreshCw
              className={`h-4 w-4 mr-2 ${isLoading ? "animate-spin" : ""}`}
            />
            Làm mới
          </Button>
          <Button onClick={openCreate}>
            <Plus className="h-4 w-4 mr-2" />
            Tạo gói mới
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-4 mt-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tổng số gói</CardTitle>
            <Package className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {isLoading ? <Skeleton className="h-7 w-12" /> : total}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Đang bán</CardTitle>
            <CheckCircle2 className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              {isLoading ? <Skeleton className="h-7 w-12" /> : stats.active}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Đã tắt</CardTitle>
            <XCircle className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-600">
              {isLoading ? <Skeleton className="h-7 w-12" /> : stats.inactive}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Nổi bật</CardTitle>
            <Star className="h-4 w-4 text-amber-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-amber-600">
              {isLoading ? (
                <Skeleton className="h-7 w-12" />
              ) : (
                plans.filter((p) => p.isFeatured).length
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Plans table */}
      <Card className="mt-6">
        <CardHeader>
          <CardTitle>Danh sách gói ({plans.length})</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {error ? (
            <div className="p-8 text-center text-red-500">{error}</div>
          ) : isLoading ? (
            <div className="p-6 space-y-3">
              {Array.from({ length: 4 }).map((_, i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : plans.length === 0 ? (
            <div className="p-10 text-center text-muted-foreground">
              Chưa có gói nào. Nhấn "Tạo gói mới" để bắt đầu.
            </div>
          ) : (
            <div className="divide-y">
              {plans.map((plan) => (
                <div
                  key={plan.id}
                  className="flex items-center gap-4 p-4 hover:bg-muted/30"
                >
                  {/* Sort controls */}
                  <div className="flex flex-col gap-0.5">
                    <Button
                      size="icon"
                      variant="ghost"
                      className="h-5 w-5"
                      onClick={() => moveSort(plan, -1)}
                      title="Tăng thứ tự"
                    >
                      <ChevronUp className="h-3 w-3" />
                    </Button>
                    <Button
                      size="icon"
                      variant="ghost"
                      className="h-5 w-5"
                      onClick={() => moveSort(plan, +1)}
                      title="Giảm thứ tự"
                    >
                      <ChevronDown className="h-3 w-3" />
                    </Button>
                  </div>

                  {/* Plan info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-semibold">{plan.name}</span>
                      {plan.badge && (
                        <Badge variant="secondary" className="text-xs">
                          {plan.badge}
                        </Badge>
                      )}
                      <Badge className={THEME_COLORS[plan.theme || "blue"]}>
                        {INTERVAL_LABELS[plan.interval]}
                      </Badge>
                      {plan.isFeatured && (
                        <Badge
                          variant="default"
                          className="bg-amber-500 hover:bg-amber-600"
                        >
                          <Star className="h-3 w-3 mr-1" /> Nổi bật
                        </Badge>
                      )}
                      {!plan.isActive && (
                        <Badge
                          variant="outline"
                          className="border-orange-500 text-orange-600"
                        >
                          Đã tắt
                        </Badge>
                      )}
                    </div>
                    <div className="flex items-center gap-3 text-xs text-muted-foreground mt-1">
                      <code className="bg-muted px-1.5 py-0.5 rounded">
                        {plan.planCode}
                      </code>
                      <span>·</span>
                      <span>{PROVIDER_LABELS[plan.provider]}</span>
                      <span>·</span>
                      <span>{plan.productId}</span>
                      {plan.trialDays > 0 && (
                        <>
                          <span>·</span>
                          <span>🎁 Trial {plan.trialDays} ngày</span>
                        </>
                      )}
                    </div>
                  </div>

                  {/* Price */}
                  <div className="text-right">
                    <div className="text-lg font-bold">
                      {formatVND(plan.priceVND)}
                    </div>
                    {plan.priceUSD != null && plan.priceUSD > 0 && (
                      <div className="text-xs text-muted-foreground">
                        ${plan.priceUSD}
                      </div>
                    )}
                  </div>

                  {/* Actions */}
                  <div className="flex gap-1">
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => handleToggleFeatured(plan)}
                      title={
                        plan.isFeatured ? "Bỏ nổi bật" : "Đánh dấu nổi bật"
                      }
                    >
                      {plan.isFeatured ? (
                        <StarOff className="h-4 w-4 text-amber-500" />
                      ) : (
                        <Star className="h-4 w-4" />
                      )}
                    </Button>
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => handleToggleActive(plan.id, plan.isActive)}
                      title={plan.isActive ? "Tắt gói" : "Bật gói"}
                    >
                      {plan.isActive ? (
                        <EyeOff className="h-4 w-4" />
                      ) : (
                        <Eye className="h-4 w-4 text-green-500" />
                      )}
                    </Button>
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => openEdit(plan)}
                      title="Chỉnh sửa"
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => handleDelete(plan.id)}
                      title="Xoá"
                    >
                      <Trash2 className="h-4 w-4 text-red-500" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Edit/Create modal */}
      {showModal && (
        <PlanFormModal
          initial={editing}
          onClose={closeModal}
          onSave={handleSave}
        />
      )}
    </>
  );
}

function computeStats(plans: SubscriptionPlan[]): PlanStats {
  const stats: PlanStats = {
    total: plans.length,
    active: plans.filter((p) => p.isActive).length,
    inactive: plans.filter((p) => !p.isActive).length,
    byProvider: { google_play: 0, app_store: 0, web: 0 },
    byInterval: { monthly: 0, quarterly: 0, yearly: 0, lifetime: 0 },
  };
  plans.forEach((p) => {
    stats.byProvider[p.provider]++;
    stats.byInterval[p.interval]++;
  });
  return stats;
}

// ─── Plan Form Modal ─────────────────────────────────────────────────────────

interface PlanFormModalProps {
  initial: SubscriptionPlan | null;
  onClose: () => void;
  onSave: (data: any) => Promise<void>;
}

function PlanFormModal({ initial, onClose, onSave }: PlanFormModalProps) {
  const [form, setForm] = useState<any>({
    planCode: initial?.planCode ?? "",
    entitlementId: initial?.entitlementId ?? "vip",
    name: initial?.name ?? "",
    nameEn: initial?.nameEn ?? "",
    description: initial?.description ?? "",
    priceVND: initial?.priceVND ?? 0,
    priceUSD: initial?.priceUSD ?? 0,
    interval: initial?.interval ?? "monthly",
    durationDays: initial?.durationDays ?? 30,
    trialDays: initial?.trialDays ?? 0,
    productId: initial?.productId ?? "",
    provider: initial?.provider ?? "google_play",
    features: initial?.features ?? [],
    isFeatured: initial?.isFeatured ?? false,
    sortOrder: initial?.sortOrder ?? 0,
    isActive: initial?.isActive ?? true,
    badge: initial?.badge ?? "",
    theme: initial?.theme ?? "blue",
    internalNote: initial?.internalNote ?? "",
  });
  const [featureInput, setFeatureInput] = useState("");
  const [saving, setSaving] = useState(false);

  const updateField = (key: string, value: any) => {
    setForm((prev: any) => ({ ...prev, [key]: value }));
  };

  const addFeature = () => {
    const trimmed = featureInput.trim();
    if (!trimmed) return;
    updateField("features", [...(form.features || []), trimmed]);
    setFeatureInput("");
  };

  const removeFeature = (feat: string) => {
    updateField(
      "features",
      form.features.filter((f: string) => f !== feat),
    );
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      await onSave({
        ...form,
        priceVND: Number(form.priceVND) || 0,
        priceUSD: form.priceUSD ? Number(form.priceUSD) : undefined,
        durationDays:
          form.interval === "lifetime" ? null : Number(form.durationDays) || 30,
        trialDays: Number(form.trialDays) || 0,
        sortOrder: Number(form.sortOrder) || 0,
      });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div
      className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4 overflow-y-auto"
      onClick={onClose}
    >
      <div
        className="bg-white dark:bg-gray-900 rounded-xl shadow-2xl p-6 w-full max-w-2xl my-8"
        onClick={(e) => e.stopPropagation()}
      >
        <h3 className="text-lg font-bold mb-4">
          {initial ? `Chỉnh sửa: ${initial.name}` : "Tạo gói mới"}
        </h3>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Row 1: planCode + entitlementId */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label
                htmlFor="planCode"
                className="text-sm font-medium block mb-1"
              >
                Plan code *
              </label>
              <Input
                id="planCode"
                value={form.planCode}
                onChange={(e) => updateField("planCode", e.target.value)}
                placeholder="vip_monthly"
                required
                pattern="[a-z0-9_]+"
                disabled={!!initial}
              />
              <p className="text-xs text-muted-foreground mt-1">
                chỉ gồm chữ thường, số, gạch dưới
              </p>
            </div>
            <div>
              <label
                htmlFor="entitlementId"
                className="text-sm font-medium block mb-1"
              >
                Entitlement ID
              </label>
              <Input
                id="entitlementId"
                value={form.entitlementId}
                onChange={(e) => updateField("entitlementId", e.target.value)}
                placeholder="vip"
              />
            </div>
          </div>

          {/* Row 2: names */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label
                htmlFor="planName"
                className="text-sm font-medium block mb-1"
              >
                Tên tiếng Việt *
              </label>
              <Input
                id="planName"
                value={form.name}
                onChange={(e) => updateField("name", e.target.value)}
                placeholder="VIP 1 tháng"
                required
              />
            </div>
            <div>
              <label
                htmlFor="planNameEn"
                className="text-sm font-medium block mb-1"
              >
                Tên tiếng Anh
              </label>
              <Input
                id="planNameEn"
                value={form.nameEn}
                onChange={(e) => updateField("nameEn", e.target.value)}
                placeholder="VIP Monthly"
              />
            </div>
          </div>

          <div>
            <label
              htmlFor="planDescription"
              className="text-sm font-medium block mb-1"
            >
              Mô tả
            </label>
            <Input
              id="planDescription"
              value={form.description}
              onChange={(e) => updateField("description", e.target.value)}
              placeholder="Mô tả ngắn hiển thị trên paywall..."
            />
          </div>

          {/* Row 3: prices */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label
                htmlFor="priceVND"
                className="text-sm font-medium block mb-1"
              >
                Giá VND *
              </label>
              <Input
                id="priceVND"
                type="number"
                value={form.priceVND}
                onChange={(e) => updateField("priceVND", e.target.value)}
                min="0"
                required
              />
              <p className="text-xs text-muted-foreground mt-1">vd: 99000</p>
            </div>
            <div>
              <label
                htmlFor="priceUSD"
                className="text-sm font-medium block mb-1"
              >
                Giá USD (optional)
              </label>
              <Input
                id="priceUSD"
                type="number"
                step="0.01"
                value={form.priceUSD}
                onChange={(e) => updateField("priceUSD", e.target.value)}
                min="0"
              />
            </div>
          </div>

          {/* Row 4: interval + duration */}
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label
                htmlFor="interval"
                className="text-sm font-medium block mb-1"
              >
                Chu kỳ *
              </label>
              <select
                id="interval"
                className="w-full h-10 px-3 rounded-md border border-input bg-background text-sm"
                value={form.interval}
                onChange={(e) => updateField("interval", e.target.value)}
                required
              >
                <option value="monthly">Hàng tháng</option>
                <option value="quarterly">Hàng quý</option>
                <option value="yearly">Hàng năm</option>
                <option value="lifetime">Trọn đời</option>
              </select>
            </div>
            <div>
              <label
                htmlFor="durationDays"
                className="text-sm font-medium block mb-1"
              >
                Số ngày
              </label>
              <Input
                id="durationDays"
                type="number"
                value={form.durationDays}
                onChange={(e) => updateField("durationDays", e.target.value)}
                disabled={form.interval === "lifetime"}
                min="1"
              />
            </div>
            <div>
              <label
                htmlFor="trialDays"
                className="text-sm font-medium block mb-1"
              >
                Trial (ngày)
              </label>
              <Input
                id="trialDays"
                type="number"
                value={form.trialDays}
                onChange={(e) => updateField("trialDays", e.target.value)}
                disabled={form.interval === "lifetime"}
                min="0"
              />
            </div>
          </div>

          {/* Row 5: provider + productId */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label
                htmlFor="provider"
                className="text-sm font-medium block mb-1"
              >
                Provider *
              </label>
              <select
                id="provider"
                className="w-full h-10 px-3 rounded-md border border-input bg-background text-sm"
                value={form.provider}
                onChange={(e) => updateField("provider", e.target.value)}
                required
              >
                <option value="google_play">Google Play</option>
                <option value="app_store">App Store</option>
                <option value="web">Web</option>
              </select>
            </div>
            <div>
              <label
                htmlFor="productId"
                className="text-sm font-medium block mb-1"
              >
                Product ID *
              </label>
              <Input
                id="productId"
                value={form.productId}
                onChange={(e) => updateField("productId", e.target.value)}
                placeholder="hvac_vip_monthly"
                required
              />
              <p className="text-xs text-muted-foreground mt-1">
                SKU trên store
              </p>
            </div>
          </div>

          {/* Row 6: badge + theme + sortOrder */}
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label htmlFor="badge" className="text-sm font-medium block mb-1">
                Badge
              </label>
              <Input
                id="badge"
                value={form.badge}
                onChange={(e) => updateField("badge", e.target.value)}
                placeholder="Tiết kiệm 30%"
              />
            </div>
            <div>
              <label htmlFor="theme" className="text-sm font-medium block mb-1">
                Theme
              </label>
              <select
                id="theme"
                className="w-full h-10 px-3 rounded-md border border-input bg-background text-sm"
                value={form.theme}
                onChange={(e) => updateField("theme", e.target.value)}
              >
                <option value="blue">Blue (mặc định)</option>
                <option value="purple">Purple</option>
                <option value="gold">Gold (VIP)</option>
              </select>
            </div>
            <div>
              <label
                htmlFor="sortOrder"
                className="text-sm font-medium block mb-1"
              >
                Thứ tự
              </label>
              <Input
                id="sortOrder"
                type="number"
                value={form.sortOrder}
                onChange={(e) => updateField("sortOrder", e.target.value)}
              />
            </div>
          </div>

          {/* Features */}
          <div>
            <label
              htmlFor="featureInput"
              className="text-sm font-medium block mb-1"
            >
              Tính năng nổi bật
            </label>
            <div className="flex gap-2">
              <Input
                id="featureInput"
                value={featureInput}
                onChange={(e) => setFeatureInput(e.target.value)}
                placeholder="vd: Xem toàn bộ mã lỗi"
                onKeyDown={(e) => {
                  if (e.key === "Enter") {
                    e.preventDefault();
                    addFeature();
                  }
                }}
              />
              <Button
                type="button"
                onClick={addFeature}
                aria-label="Thêm tính năng"
              >
                Thêm
              </Button>
            </div>
            {form.features?.length > 0 && (
              <ul className="mt-2 space-y-1">
                {form.features.map((feat: string) => (
                  <li
                    key={feat}
                    className="flex items-center justify-between text-sm bg-muted/40 px-3 py-1.5 rounded"
                  >
                    <span>✓ {feat}</span>
                    <button
                      type="button"
                      aria-label={`Xóa tính năng: ${feat}`}
                      className="text-red-500 text-xs hover:underline"
                      onClick={() => removeFeature(feat)}
                    >
                      Xoá
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>

          {/* Toggles */}
          <div className="flex gap-6 pt-2">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={form.isActive}
                onChange={(e) => updateField("isActive", e.target.checked)}
                className="h-4 w-4"
              />
              <span className="text-sm">Đang bán</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={form.isFeatured}
                onChange={(e) => updateField("isFeatured", e.target.checked)}
                className="h-4 w-4"
              />
              <span className="text-sm">Đánh dấu nổi bật</span>
            </label>
          </div>

          {/* Internal note */}
          <div>
            <label
              htmlFor="internalNote"
              className="text-sm font-medium block mb-1"
            >
              Ghi chú nội bộ (admin only)
            </label>
            <Input
              id="internalNote"
              value={form.internalNote}
              onChange={(e) => updateField("internalNote", e.target.value)}
              placeholder="Không hiển thị trên mobile..."
            />
          </div>

          <div className="flex gap-3 pt-4">
            <Button
              type="button"
              variant="outline"
              aria-label="Đóng"
              className="flex-1"
              onClick={onClose}
            >
              Huỷ
            </Button>
            <Button type="submit" className="flex-1" disabled={saving}>
              {saving ? "Đang lưu..." : initial ? "Cập nhật" : "Tạo gói"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}
