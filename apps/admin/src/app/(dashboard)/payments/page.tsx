"use client";

import { useState, useCallback } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { usePayments } from "@/hooks";
import { CreditCard, TrendingUp, Users, Clock, RefreshCw, Search, RotateCcw, CheckCircle, XCircle } from "lucide-react";
import { format } from "date-fns";
import { vi } from "date-fns/locale";
import type { Payment } from "@/types";

type FilterType = "all" | "active" | "expired" | "cancelled" | "refunded" | "pending";

const STATUS_LABELS: Record<string, string> = {
  active: "Đang hoạt động",
  pending: "Chờ xử lý",
  expired: "Hết hạn",
  cancelled: "Đã hủy",
  refunded: "Đã hoàn tiền",
};

const STATUS_VARIANTS: Record<string, "default" | "secondary" | "destructive" | "outline"> = {
  active: "default",
  pending: "secondary",
  expired: "outline",
  cancelled: "destructive",
  refunded: "destructive",
};

export default function PaymentsPage() {
  const [filter, setFilter] = useState<FilterType>("all");
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  // Sync modal state
  const [showSyncModal, setShowSyncModal] = useState(false);
  const [syncToken, setSyncToken] = useState("");
  const [syncProductId, setSyncProductId] = useState("");
  const [syncUserId, setSyncUserId] = useState("");
  const [syncUserEmail, setSyncUserEmail] = useState("");
  const [syncType, setSyncType] = useState<"subscription" | "inapp">("subscription");
  const [isSyncing, setIsSyncing] = useState(false);

  const { payments, stats, total, isLoading, error, refetch, syncPayment, updatePaymentStatus } = usePayments({ filter, search });

  const handleSearch = useCallback(() => setSearch(searchInput.trim()), [searchInput]);
  const handleKeyDown = (e: React.KeyboardEvent) => { if (e.key === "Enter") handleSearch(); };

  const formatDate = (timestamp: any) => {
    if (!timestamp) return "—";
    try {
      const date = timestamp?.toDate?.() || new Date(timestamp);
      return format(date, "dd/MM/yyyy HH:mm", { locale: vi });
    } catch { return "—"; }
  };

  const formatVND = (amount: number) => {
    if (!amount) return "—";
    return new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND" }).format(amount);
  };

  const handleSync = async () => {
    if (!syncToken || !syncProductId) {
      alert("Vui lòng nhập Purchase Token và Product ID.");
      return;
    }
    setIsSyncing(true);
    try {
      const result = await syncPayment({
        purchaseToken: syncToken,
        productId: syncProductId,
        purchaseType: syncType,
        userId: syncUserId || undefined,
        userEmail: syncUserEmail || undefined,
      });
      alert(`✅ Sync thành công! Order: ${result.orderId}, Trạng thái: ${result.status}`);
      setShowSyncModal(false);
      setSyncToken(""); setSyncProductId(""); setSyncUserId(""); setSyncUserEmail("");
    } catch (err: any) {
      alert("❌ Lỗi: " + err.message);
    } finally {
      setIsSyncing(false);
    }
  };

  const handleStatusChange = async (id: string, status: Payment["status"]) => {
    if (!confirm(`Xác nhận đổi trạng thái sang "${STATUS_LABELS[status]}"?`)) return;
    setActionLoading(id);
    try {
      await updatePaymentStatus(id, status);
    } catch (err: any) {
      alert("Lỗi: " + err.message);
    } finally {
      setActionLoading(null);
    }
  };

  const filterTabs: { label: string; value: FilterType }[] = [
    { label: "Tất cả", value: "all" },
    { label: "Đang active", value: "active" },
    { label: "Chờ xử lý", value: "pending" },
    { label: "Hết hạn", value: "expired" },
    { label: "Đã hủy", value: "cancelled" },
  ];

  return (
    <>
      <div className="flex items-center justify-between">
        <h2 className="text-3xl font-bold tracking-tight">Quản lý thanh toán</h2>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => setShowSyncModal(true)}>
            <RotateCcw className="h-4 w-4 mr-2" />
            Sync thủ công
          </Button>
          <Button variant="outline" size="sm" onClick={refetch} disabled={isLoading}>
            <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? "animate-spin" : ""}`} />
            Làm mới
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-4 mt-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Subscribers active</CardTitle>
            <Users className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">
              {isLoading ? <Skeleton className="h-7 w-12" /> : stats.activeSubscribers}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Doanh thu tháng này</CardTitle>
            <TrendingUp className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-blue-600">
              {isLoading ? <Skeleton className="h-7 w-24" /> : formatVND(stats.revenueThisMonth)}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Mới trong 7 ngày</CardTitle>
            <CreditCard className="h-4 w-4 text-purple-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-purple-600">
              {isLoading ? <Skeleton className="h-7 w-12" /> : stats.newThisWeek}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Chờ xác nhận</CardTitle>
            <Clock className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-600">
              {isLoading ? <Skeleton className="h-7 w-12" /> : stats.pendingCount}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters + Search */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4 mt-6">
        <div className="flex gap-2 flex-wrap">
          {filterTabs.map(tab => (
            <Button
              key={tab.value}
              size="sm"
              variant={filter === tab.value ? "default" : "outline"}
              onClick={() => setFilter(tab.value)}
            >
              {tab.label}
            </Button>
          ))}
        </div>
        <div className="flex gap-2 ml-auto">
          <Input
            placeholder="Tìm theo email, Order ID..."
            value={searchInput}
            onChange={e => setSearchInput(e.target.value)}
            onKeyDown={handleKeyDown}
            className="w-64"
          />
          <Button size="sm" variant="outline" onClick={handleSearch}>
            <Search className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Table */}
      <Card className="mt-4">
        <CardContent className="p-0">
          {error ? (
            <div className="p-8 text-center text-red-500">{error}</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Order ID</TableHead>
                  <TableHead>Người dùng</TableHead>
                  <TableHead>Sản phẩm</TableHead>
                  <TableHead>Số tiền</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead>Auto-renew</TableHead>
                  <TableHead>Ngày mua</TableHead>
                  <TableHead>Hết hạn</TableHead>
                  <TableHead className="text-right">Hành động</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  Array.from({ length: 5 }).map((_, i) => (
                    <TableRow key={i}>
                      {Array.from({ length: 9 }).map((_, j) => (
                        <TableCell key={j}><Skeleton className="h-5 w-full" /></TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : payments.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={9} className="text-center text-muted-foreground py-10">
                      Không có giao dịch nào.
                    </TableCell>
                  </TableRow>
                ) : (
                  payments.map((payment) => (
                    <TableRow key={payment.id}>
                      <TableCell className="font-mono text-xs max-w-[120px] truncate" title={payment.orderId}>
                        {payment.orderId?.slice(0, 20)}…
                      </TableCell>
                      <TableCell>
                        <div className="text-sm">{payment.userEmail || payment.userId || "—"}</div>
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">{payment.productId}</TableCell>
                      <TableCell className="text-sm font-medium">{formatVND(payment.amount)}</TableCell>
                      <TableCell>
                        <Badge variant={STATUS_VARIANTS[payment.status] || "outline"}>
                          {STATUS_LABELS[payment.status] || payment.status}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-center text-sm">
                        {payment.purchaseType === "subscription"
                          ? payment.autoRenewing ? "✅" : "❌"
                          : "—"}
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">{formatDate(payment.purchaseTime)}</TableCell>
                      <TableCell className="text-xs text-muted-foreground">{formatDate(payment.expiryTime)}</TableCell>
                      <TableCell className="text-right">
                        <div className="flex gap-1 justify-end">
                          {payment.status === "pending" && (
                            <Button
                              size="sm"
                              variant="default"
                              disabled={actionLoading === payment.id}
                              onClick={() => handleStatusChange(payment.id, "active")}
                              title="Xác nhận"
                            >
                              {actionLoading === payment.id
                                ? <RefreshCw className="h-3 w-3 animate-spin" />
                                : <CheckCircle className="h-3 w-3" />}
                            </Button>
                          )}
                          {(payment.status === "active" || payment.status === "pending") && (
                            <Button
                              size="sm"
                              variant="destructive"
                              disabled={actionLoading === payment.id}
                              onClick={() => handleStatusChange(payment.id, "refunded")}
                              title="Hoàn tiền"
                            >
                              {actionLoading === payment.id
                                ? <RefreshCw className="h-3 w-3 animate-spin" />
                                : <XCircle className="h-3 w-3" />}
                            </Button>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Sync Modal */}
      {showSyncModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => setShowSyncModal(false)}>
          <div className="bg-white dark:bg-gray-900 rounded-xl shadow-2xl p-6 w-full max-w-md mx-4" onClick={e => e.stopPropagation()}>
            <h3 className="text-lg font-bold mb-4">Sync Purchase Token thủ công</h3>
            <div className="space-y-3">
              <div>
                <label className="text-sm font-medium block mb-1">Purchase Token <span className="text-red-500">*</span></label>
                <Input value={syncToken} onChange={e => setSyncToken(e.target.value)} placeholder="token từ Google Play..." />
              </div>
              <div>
                <label className="text-sm font-medium block mb-1">Product ID <span className="text-red-500">*</span></label>
                <Input value={syncProductId} onChange={e => setSyncProductId(e.target.value)} placeholder="vd: hvac_premium_monthly" />
              </div>
              <div>
                <label className="text-sm font-medium block mb-1">Loại</label>
                <div className="flex gap-2">
                  <Button size="sm" variant={syncType === "subscription" ? "default" : "outline"} onClick={() => setSyncType("subscription")}>Subscription</Button>
                  <Button size="sm" variant={syncType === "inapp" ? "default" : "outline"} onClick={() => setSyncType("inapp")}>One-time</Button>
                </div>
              </div>
              <div>
                <label className="text-sm font-medium block mb-1">Firebase UID (tùy chọn)</label>
                <Input value={syncUserId} onChange={e => setSyncUserId(e.target.value)} placeholder="uid người dùng..." />
              </div>
              <div>
                <label className="text-sm font-medium block mb-1">Email (tùy chọn)</label>
                <Input value={syncUserEmail} onChange={e => setSyncUserEmail(e.target.value)} placeholder="email@example.com" />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <Button variant="outline" className="flex-1" onClick={() => setShowSyncModal(false)}>Hủy</Button>
              <Button className="flex-1" disabled={isSyncing} onClick={handleSync}>
                {isSyncing ? <><RefreshCw className="h-4 w-4 mr-2 animate-spin" />Đang sync...</> : "Xác nhận Sync"}
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
