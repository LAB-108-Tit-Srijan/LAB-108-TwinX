"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { auth } from "@/lib/auth";
import {
  LayoutDashboard,
  BookOpen,
  Video,
  Users,
  HelpCircle,
  BarChart3,
  Settings,
  LogOut,
} from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/", icon: LayoutDashboard, label: "Dashboard" },
  { href: "/courses", icon: BookOpen, label: "Courses" },
  { href: "/lectures", icon: Video, label: "Lectures" },
  { href: "/students", icon: Users, label: "Students" },
  { href: "/doubts", icon: HelpCircle, label: "Doubts Analytics" },
  { href: "/reports", icon: BarChart3, label: "Reports" },
  { href: "/settings", icon: Settings, label: "Settings" },
];

export function Sidebar() {
  const pathname = usePathname();

  // Don't render sidebar on the login page
  if (pathname === '/login') return null;

  return (
    <aside className="fixed left-0 top-0 h-full w-[260px] bg-white border-r border-[#E5E7EB] flex flex-col z-30">
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-5 border-b border-[#E5E7EB]">
        <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#6C63FF] to-[#8B5CF6] flex items-center justify-center">
          <span className="text-white font-bold text-sm">AI</span>
        </div>
        <div>
          <p className="font-bold text-[#1A1A2E] text-sm leading-none">AIVA</p>
          <p className="text-[#9CA3AF] text-xs mt-0.5">Admin Panel</p>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 overflow-y-auto">
        <div className="space-y-1">
          {navItems.map((item) => {
            const active =
              item.href === "/"
                ? pathname === "/"
                : pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200",
                  active
                    ? "bg-[#6C63FF] text-white shadow-sm shadow-[#6C63FF]/30"
                    : "text-[#6B7280] hover:bg-[#F5F6FA] hover:text-[#1A1A2E]"
                )}
              >
                <item.icon size={18} />
                {item.label}
              </Link>
            );
          })}
        </div>
      </nav>

      {/* Admin profile */}
      <div className="px-4 py-4 border-t border-[#E5E7EB]">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-full bg-gradient-to-br from-[#6C63FF] to-[#00D4FF] flex items-center justify-center flex-shrink-0">
            <span className="text-white font-bold text-xs">AD</span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold text-[#1A1A2E] truncate">
              Admin
            </p>
            <p className="text-xs text-[#9CA3AF] truncate">
              admin@aiva.in
            </p>
          </div>
          <button
            onClick={() => auth.logout()}
            title="Sign out"
            className="p-1.5 rounded-lg hover:bg-[#FEF2F2] text-[#9CA3AF] hover:text-[#EF4444] transition-colors"
          >
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </aside>
  );
}
