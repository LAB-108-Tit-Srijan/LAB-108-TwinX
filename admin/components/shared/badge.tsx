import { cn } from "@/lib/utils";

interface BadgeProps {
  label: string;
  variant?: "success" | "warning" | "error" | "default" | "info";
}

const variants = {
  success: "bg-[#10B981]/10 text-[#10B981] border-[#10B981]/20",
  warning: "bg-[#F59E0B]/10 text-[#F59E0B] border-[#F59E0B]/20",
  error: "bg-[#EF4444]/10 text-[#EF4444] border-[#EF4444]/20",
  info: "bg-[#00D4FF]/10 text-[#0096C7] border-[#00D4FF]/20",
  default: "bg-[#6C63FF]/10 text-[#6C63FF] border-[#6C63FF]/20",
};

export function Badge({ label, variant = "default" }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center px-2.5 py-0.5 rounded-lg text-xs font-semibold border",
        variants[variant]
      )}
    >
      {label}
    </span>
  );
}
