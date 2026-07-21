"use client";

import { useState, useCallback } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { useUsers } from "@/hooks";
import { Users, Crown, UserX, Search, RefreshCw, ShieldOff, Shield } from "lucide-react";
import { format } from "date-fns";
import { vi } from "date-fns/locale";

type FilterType = "all" | "vip" | "free" | "disabled";

const tabs: { label: string; value: FilterType }[] = [
  { label: "Tất cả", value: "all" },
  { label: "VIP", value: "vip" },
  { label: "Free", value: "free" },
  { label: "Bị khóa", value: "disabled" },
];

function formatDate(timestamp: any) {
  if (!timestamp) return "—";
  try {
    const date = timestamp?.toDate?.() || new Date(timestamp);
    return format(date, "dd/MM/yyyy", { locale: vi });
  } catch {
    return "—";
  }
}

export default function UsersPage() {
  const [filter, setFilter] = useState<FilterType>("all");
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const { users, total, isLoading, error, refetch, updateUser } = useUsers({ filter, search });

  const handleSearch = useCallback(() => {
    setSearch(searchInput.trim());
  }, [searchInput]);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter") handleSearch();
  };

  const handleToggleVip = async (uid: string, currentVip: boolean) => {
    setActionLoading(uid);
    try {
      if (currentVip) {
        await updateUser(uid, { isPremium: false });
      } else {
        await updateUser(uid, { isPremium: true, premiumDays: 30 });
      }
    } catch (err: any) {
      alert("Lỗi: " + err.message);
    } finally {
      setActionLoading(null);
    }
  };

  const handleToggleStatus = async (uid: string, currentStatus: string) => {
    setActionLoading(uid + "_status");
    try {
      const newStatus = currentStatus === "disabled" ? "active" : "disabled";
      await updateUser(uid, { status: newStatus as "active" | "disabled" });
    } catch (err: any) {
      alert("Lỗi: " + err.message);
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <>
      <div className="flex items-center justify-between">
        <h2 className="text-3xl font-bold tracking-tight">Quản lý người dùng</h2>
        <Button variant="outline" size="sm" onClick={refetch} disabled={isLoading}>
          <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? "animate-spin" : ""}`} />
          Làm mới
        </Button>
      </div>

      {/* Stats cards */}
      <div className="grid gap-4 md:grid-cols-3 mt-6">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tổng người dùng</CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{isLoading ? <Skeleton className="h-7 w-16" /> : total}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Thành viên VIP</CardTitle>
            <Crown className="h-4 w-4 text-yellow-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-yellow-600">
              {isLoading ? <Skeleton className="h-7 w-16" /> : users.filter(u => u.isPremium).length}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Tài khoản bị khóa</CardTitle>
            <UserX className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-red-600">
              {isLoading ? <Skeleton className="h-7 w-16" /> : users.filter(u => u.status === "disabled").length}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters + Search */}
      <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4 mt-6">
        <div className="flex gap-2 flex-wrap">
          {tabs.map(tab => (
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
            placeholder="Tìm theo email hoặc tên..."
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
                  <TableHead>Người dùng</TableHead>
                  <TableHead>Trạng thái</TableHead>
                  <TableHead>VIP</TableHead>
                  <TableHead>Hết hạn VIP</TableHead>
                  <TableHead>Ngày đăng ký</TableHead>
                  <TableHead className="text-right">Hành động</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {isLoading ? (
                  Array.from({ length: 6 }).map((_, i) => (
                    <TableRow key={i}>
                      {Array.from({ length: 6 }).map((_, j) => (
                        <TableCell key={j}><Skeleton className="h-5 w-full" /></TableCell>
                      ))}
                    </TableRow>
                  ))
                ) : users.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={6} className="text-center text-muted-foreground py-10">
                      Không có người dùng nào.
                    </TableCell>
                  </TableRow>
                ) : (
                  users.map((user) => (
                    <TableRow key={user.uid}>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <div className="h-8 w-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center font-bold text-sm shrink-0">
                            {user.email?.charAt(0).toUpperCase() || "?"}
                          </div>
                          <div>
                            <div className="font-medium text-sm">{user.displayName || "—"}</div>
                            <div className="text-xs text-muted-foreground">{user.email}</div>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant={user.status === "disabled" ? "destructive" : "secondary"}>
                          {user.status === "disabled" ? "Bị khóa" : "Hoạt động"}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {user.isPremium ? (
                          <Badge className="bg-yellow-100 text-yellow-800 border-yellow-300">
                            <Crown className="h-3 w-3 mr-1" />VIP
                          </Badge>
                        ) : (
                          <Badge variant="outline">Free</Badge>
                        )}
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {user.isPremium ? formatDate(user.premiumExpiry) : "—"}
                      </TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {formatDate(user.createdAt)}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex gap-2 justify-end">
                          <Button
                            size="sm"
                            variant={user.isPremium ? "outline" : "default"}
                            disabled={actionLoading === user.uid}
                            onClick={() => handleToggleVip(user.uid, user.isPremium)}
                            title={user.isPremium ? "Thu hồi VIP" : "Cấp VIP 30 ngày"}
                          >
                            {actionLoading === user.uid ? (
                              <RefreshCw className="h-3 w-3 animate-spin" />
                            ) : user.isPremium ? (
                              <><ShieldOff className="h-3 w-3 mr-1" />Thu hồi</>
                            ) : (
                              <><Crown className="h-3 w-3 mr-1" />Cấp VIP</>
                            )}
                          </Button>
                          <Button
                            size="sm"
                            variant={user.status === "disabled" ? "default" : "destructive"}
                            disabled={actionLoading === user.uid + "_status"}
                            onClick={() => handleToggleStatus(user.uid, user.status)}
                            title={user.status === "disabled" ? "Mở khóa tài khoản" : "Khóa tài khoản"}
                          >
                            {actionLoading === user.uid + "_status" ? (
                              <RefreshCw className="h-3 w-3 animate-spin" />
                            ) : user.status === "disabled" ? (
                              <><Shield className="h-3 w-3 mr-1" />Mở khóa</>
                            ) : (
                              <><UserX className="h-3 w-3 mr-1" />Khóa</>
                            )}
                          </Button>
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
    </>
  );
}
