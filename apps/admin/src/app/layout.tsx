import type { Metadata } from "next";
import { Fira_Sans, Fira_Code } from "next/font/google";
import "./globals.css";

const firaSans = Fira_Sans({
  variable: "--font-fira-sans",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
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
      className={`${firaSans.variable} ${firaCode.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">
        <ThemeWatcher />
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
