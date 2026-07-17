"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Plus, Trash2, ShieldAlert } from "lucide-react";
import ProtectedRoute from "@/components/ProtectedRoute";
import Header from "@/components/Header";
import { db } from "@/lib/firebase";
import { collection, doc, setDoc, deleteDoc, query, orderBy, onSnapshot, serverTimestamp } from "firebase/firestore";

interface Brand {
  id: string;
  name: string;
  createdAt?: any;
}

export default function BrandsPage() {
  const [brands, setBrands] = useState<Brand[]>([]);
  const [slug, setSlug] = useState("");
  const [name, setName] = useState("");
  const [isSaving, setIsSaving] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, "brands"), orderBy("createdAt", "desc"));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const brandsList: Brand[] = [];
      snapshot.forEach((doc) => {
        const data = doc.data();
        brandsList.push({
          id: doc.id,
          name: data.name || "",
          createdAt: data.createdAt,
        });
      });
      setBrands(brandsList);
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleAddBrand = async (e: React.FormEvent) => {
    e.preventDefault();
    
    // Clean and validate slug and name
    const cleanedSlug = slug.trim().toLowerCase().replace(/[^a-z0-9-]/g, "-");
    const cleanedName = name.trim();

    if (!cleanedSlug || !cleanedName) {
      alert("Vui lòng nhập đầy đủ mã và tên hãng sản xuất.");
      return;
    }

    setIsSaving(true);
    try {
      // Create or update brand document with slug as ID
      await setDoc(doc(db, "brands", cleanedSlug), {
        name: cleanedName,
        createdAt: serverTimestamp(),
      });

      setSlug("");
      setName("");
      alert("Thêm hãng sản xuất thành công!");
    } catch (error: any) {
      console.error(error);
      alert("Lỗi khi thêm hãng sản xuất: " + error.message);
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteBrand = async (brandId: string, brandName: string) => {
    if (!confirm(`Bạn có chắc chắn muốn xóa hãng "${brandName}" không? Các bài viết thuộc hãng này sẽ bị ảnh hưởng.`)) {
      return;
    }

    try {
      await deleteDoc(doc(db, "brands", brandId));
      alert("Đã xóa hãng sản xuất thành công!");
    } catch (error: any) {
      console.error(error);
      alert("Lỗi khi xóa hãng sản xuất: " + error.message);
    }
  };

  return (
    <ProtectedRoute>
      <div className="flex min-h-screen w-full flex-col bg-gray-50 dark:bg-gray-900">
        <Header />

        <main className="flex-1 space-y-6 p-8">
          <div className="flex items-center justify-between">
            <h2 className="text-3xl font-bold tracking-tight">Quản lý Hãng sản xuất</h2>
          </div>

          <div className="grid gap-6 md:grid-cols-3">
            {/* Create Brand Card */}
            <Card className="md:col-span-1 h-fit">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-lg">
                  <Plus className="h-5 w-5 text-blue-600" />
                  Thêm hãng sản xuất mới
                </CardTitle>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleAddBrand} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="slug">Mã hãng (Slug ID)</Label>
                    <Input
                      id="slug"
                      placeholder="Ví dụ: daikin, panasonic, lg"
                      value={slug}
                      onChange={(e) => setSlug(e.target.value)}
                    />
                    <p className="text-xs text-muted-foreground">
                      * Chỉ dùng chữ thường không dấu, số và gạch ngang (ví dụ: `panasonic`, `lg`).
                    </p>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="name">Tên hãng hiển thị</Label>
                    <Input
                      id="name"
                      placeholder="Ví dụ: Daikin, Panasonic, LG"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                    />
                  </div>
                  <Button type="submit" className="w-full" disabled={isSaving}>
                    {isSaving ? "Đang lưu..." : "Thêm hãng sản xuất"}
                  </Button>
                </form>
              </CardContent>
            </Card>

            {/* List Brands Card */}
            <Card className="md:col-span-2">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-lg">
                  <ShieldAlert className="h-5 w-5 text-blue-600" />
                  Danh sách hãng sản xuất hiện tại
                </CardTitle>
              </CardHeader>
              <CardContent>
                {isLoading ? (
                  <div className="py-8 text-center text-muted-foreground animate-pulse">
                    Đang tải danh sách hãng sản xuất...
                  </div>
                ) : brands.length === 0 ? (
                  <div className="py-8 text-center text-muted-foreground">
                    Chưa có hãng sản xuất nào được đăng ký.
                  </div>
                ) : (
                  <div className="border rounded-md">
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>Mã (Slug ID)</TableHead>
                          <TableHead>Tên hãng sản xuất</TableHead>
                          <TableHead className="w-[100px] text-right">Thao tác</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {brands.map((brand) => (
                          <TableRow key={brand.id}>
                            <TableCell className="font-mono text-sm text-blue-600 dark:text-blue-400">
                              {brand.id}
                            </TableCell>
                            <TableCell className="font-medium">{brand.name}</TableCell>
                            <TableCell className="text-right">
                              <Button
                                variant="ghost"
                                size="icon"
                                onClick={() => handleDeleteBrand(brand.id, brand.name)}
                                title="Xóa hãng sản xuất"
                              >
                                <Trash2 className="h-4 w-4 text-red-500 hover:text-red-700" />
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
        </main>
      </div>
    </ProtectedRoute>
  );
}
