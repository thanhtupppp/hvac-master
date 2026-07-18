"use client";

import ProtectedRoute from "@/components/ProtectedRoute";
import Header from "@/components/Header";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ProtectedRoute>
      <div className="flex min-h-screen w-full flex-col bg-background">
        <Header />
        <main className="flex-1 space-y-6 p-8">{children}</main>
      </div>
    </ProtectedRoute>
  );
}
