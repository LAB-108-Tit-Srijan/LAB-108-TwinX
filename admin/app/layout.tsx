import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Sidebar } from "@/components/layout/sidebar";
import { ContentWrapper } from "@/components/layout/content-wrapper";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "AIVA Admin Panel",
  description: "LMS Dashboard for AIVA",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="h-full">
      <body className={`${inter.className} h-full bg-[#F8F9FC] antialiased`}>
        <Sidebar />
        <ContentWrapper>{children}</ContentWrapper>
      </body>
    </html>
  );
}
