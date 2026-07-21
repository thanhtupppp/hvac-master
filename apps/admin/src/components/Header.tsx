"use client";

import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";
import { Settings, LogOut } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";

const navItems = [
  { label: "Tổng quan", href: "/" },
  { label: "Bài viết", href: "/articles" },
  { label: "Danh mục", href: "/categories" },
  { label: "Hãng sản xuất", href: "/brands" },
  { label: "Người dùng", href: "/users" },
  { label: "Thanh toán", href: "/payments" },
  { label: "Gói VIP", href: "/plans" },
];

export default function Header() {
  const { logout, user } = useAuth();
  const pathname = usePathname();

  return (
    <header className="flex h-16 items-center border-b bg-white dark:bg-gray-950 px-6">
      <Link
        href="/"
        className="flex items-center gap-2 font-bold text-xl text-blue-600"
      >
        HVAC Pro Admin
      </Link>
      <nav className="ml-10 flex gap-6 text-sm font-medium">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={
                isActive
                  ? "text-gray-900 dark:text-gray-100 font-bold"
                  : "text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100"
              }
            >
              {item.label}
            </Link>
          );
        })}
      </nav>
      <div className="ml-auto flex items-center gap-4">
        <Button variant="ghost" size="icon" title="Cài đặt">
          <Settings className="h-5 w-5" />
        </Button>
        <div
          className="h-8 w-8 rounded-full bg-blue-600 text-white flex items-center justify-center font-bold text-sm"
          title={user?.email || "Admin"}
        >
          {user?.email?.charAt(0).toUpperCase() || "A"}
        </div>
        <Button variant="ghost" size="icon" onClick={logout} title="Đăng xuất">
          <LogOut className="h-5 w-5 text-red-500" />
        </Button>
      </div>
    </header>
  );
}
