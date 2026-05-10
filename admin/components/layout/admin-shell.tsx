"use client";

import { usePathname } from "next/navigation";
import { Sidebar } from "./sidebar";
import { ContentWrapper } from "./content-wrapper";

export function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  if (pathname === "/login") {
    return <>{children}</>;
  }

  return (
    <>
      <Sidebar />
      <ContentWrapper>{children}</ContentWrapper>
    </>
  );
}
