import type { Metadata } from "next";
import { Lora, Fira_Code } from "next/font/google";
import "./globals.css";

const lora = Lora({
  variable: "--font-lora",
  subsets: ["latin", "vietnamese"],
  weight: ["400", "500", "600", "700"],
});

const firaCode = Fira_Code({
  variable: "--font-fira-code",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "HVAC Pro Admin - Hệ thống Quản trị Tra cứu Kỹ thuật",
  description: "Hệ thống quản trị chuyên nghiệp cho ứng dụng tra cứu kỹ thuật HVAC Pro",
};

import { AuthProvider } from "@/contexts/AuthContext";
import ThemeWatcher from "@/components/ThemeWatcher";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${lora.variable} ${firaCode.variable} h-full antialiased`}
      suppressHydrationWarning
    >
      <body className="min-h-full flex flex-col">
        <ThemeWatcher />
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
