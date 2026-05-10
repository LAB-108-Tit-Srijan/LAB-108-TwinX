"use client";

import { Search, Bell } from "lucide-react";

interface HeaderProps {
  title: string;
}

export function Header({ title }: HeaderProps) {
  return (
    <header className="h-16 bg-white border-b border-[#E5E7EB] flex items-center px-6 gap-4 sticky top-0 z-20">
      <h1 className="text-lg font-bold text-[#1A1A2E] flex-1">{title}</h1>
      <div className="flex items-center gap-4">
        <div className="relative">
          <Search
            size={16}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-[#9CA3AF]"
          />
          <input
            placeholder="Search..."
            className="pl-9 pr-4 py-2 text-sm bg-[#F5F6FA] border border-[#E5E7EB] rounded-xl w-56 focus:outline-none focus:border-[#6C63FF] focus:ring-2 focus:ring-[#6C63FF]/20 transition-all"
          />
        </div>
        <button className="relative p-2 rounded-xl hover:bg-[#F5F6FA] transition-colors">
          <Bell size={18} className="text-[#6B7280]" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-[#EF4444] rounded-full" />
        </button>
        <div className="w-9 h-9 rounded-full bg-gradient-to-br from-[#6C63FF] to-[#8B5CF6] flex items-center justify-center cursor-pointer">
          <span className="text-white font-bold text-xs">AD</span>
        </div>
      </div>
    </header>
  );
}
