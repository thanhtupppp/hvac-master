import type { Metadata } from "next";
import { Lora, Fira_Code } from "next/font/google";
import "./globals.css";
import { AuthProvider } from "@/contexts/AuthContext";
import ThemeWatcher from "@/components/ThemeWatcher";

const lora = Lora({
  variable: "--font-lora",
  subsets: ["latin", "vietnamese"],
  weight: ["400", "600", "700"], // Trimmed weight list for faster page load times
});

const firaCode = Fira_Code({
  variable: "--font-fira-code",
  subsets: ["latin"],
  weight: ["400", "600"], // Trimmed weight list for faster page load times
});

export const metadata: Metadata = {
  title: "HVAC Pro Admin - Hệ thống Quản trị Tra cứu Kỹ thuật",
  description: "Hệ thống quản trị chuyên nghiệp cho ứng dụng tra cứu kỹ thuật HVAC Pro",
  robots: {
    index: false,
    follow: false,
    nocache: true,
    googleBot: {
      index: false,
      follow: false,
      noimageindex: true,
    },
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="vi"
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
