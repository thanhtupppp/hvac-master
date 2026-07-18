"use client";

import { useEffect } from "react";
import { Button } from "@/components/ui/button";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Log the error to console and send to error tracking service (e.g. Sentry)
    console.error("Root error boundary caught error:", error);
    // Sentry.captureException(error, { extra: { digest: error.digest } });
  }, [error]);

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-slate-50 dark:bg-slate-900 p-6 text-center">
      <div className="max-w-md space-y-6">
        <div className="h-16 w-16 bg-red-100 dark:bg-red-950/30 text-red-600 dark:text-red-400 rounded-full flex items-center justify-center mx-auto text-3xl">
          ⚠️
        </div>
        <div className="space-y-2">
          <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
            Đã xảy ra sự cố hệ thống!
          </h2>
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Ứng dụng gặp lỗi không mong muốn trong khi xử lý dữ liệu. Điều này có thể do kết nối mạng yếu hoặc sự cố xác thực.
          </p>
          {error.digest && (
            <p className="text-xs font-mono text-slate-400 dark:text-slate-600 bg-slate-100 dark:bg-slate-950 p-2 rounded border border-slate-200 dark:border-slate-800">
              Mã lỗi: {error.digest}
            </p>
          )}
        </div>
        <div className="flex justify-center gap-4">
          <Button onClick={() => window.location.reload()} variant="outline">
            Tải lại trang
          </Button>
          <Button onClick={() => reset()} className="bg-green-600 hover:bg-green-500 text-white">
            Thử lại
          </Button>
        </div>
      </div>
    </div>
  );
}
