"use client";

import { useEffect } from "react";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Log the error to console and send to error tracking service (e.g. Sentry)
    console.error("Global error caught in root layout:", error);
    // Sentry.captureException(error, { extra: { digest: error.digest } });
  }, [error]);

  return (
    <html lang="vi" className="h-full">
      <body className="h-full flex items-center justify-center bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-white p-6 font-sans antialiased">
        <div className="max-w-md w-full text-center space-y-6">
          <div className="h-20 w-20 bg-red-100 dark:bg-red-950/30 text-red-600 dark:text-red-400 rounded-full flex items-center justify-center mx-auto text-4xl shadow-sm">
            🚨
          </div>
          <div className="space-y-3">
            <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 dark:text-white">
              Lỗi hệ thống nghiêm trọng
            </h1>
            <p className="text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
              Ứng dụng quản trị gặp sự cố ở cấp độ cấu trúc gốc. Vui lòng tải
              lại trang. Nếu sự cố vẫn tiếp tục xảy ra, vui lòng liên hệ bộ phận
              hỗ trợ kỹ thuật.
            </p>
            {error.digest && (
              <p className="text-xs font-mono text-slate-400 dark:text-slate-600 bg-slate-100 dark:bg-slate-950 p-2.5 rounded border border-slate-200 dark:border-slate-800 inline-block">
                Mã lỗi hệ thống: {error.digest}
              </p>
            )}
          </div>
          <div className="flex justify-center gap-4">
            <button
              type="button"
              onClick={() => window.location.reload()}
              className="px-4 py-2 text-sm font-semibold rounded-md border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-950 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors shadow-sm"
            >
              Tải lại trang
            </button>
            <button
              type="button"
              onClick={() => reset()}
              className="px-4 py-2 text-sm font-semibold rounded-md bg-red-600 hover:bg-red-500 text-white transition-colors shadow-md shadow-red-500/10"
            >
              Thử lại ngay
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
