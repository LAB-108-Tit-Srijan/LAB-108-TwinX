"use client";

import { usePathname } from "next/navigation";

export function ContentWrapper({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const isLogin = pathname === "/login";

  return (
    <div className={isLogin ? "min-h-screen flex flex-col" : "ml-[260px] min-h-screen flex flex-col"}>
      {children}
    </div>
  );
}
