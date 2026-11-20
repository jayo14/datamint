import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { Slot } from "radix-ui"

import { cn } from "@/lib/utils"

const badgeVariants = cva(
  "inline-flex w-fit shrink-0 items-center justify-center gap-1.5 rounded-full px-3 py-1 text-xs font-semibold whitespace-nowrap transition-colors border",
  {
    variants: {
      variant: {
        default:
          "bg-[#74E3B6] text-[#0D1F18] border-[#5fd4a5] font-bold shadow-xs",
        secondary:
          "bg-[#EAFBF3] text-[#0D1F18] border-[#BFE3D2]",
        outline:
          "border-[#BFE3D2] bg-white text-[#3F5F52]",
        mint:
          "bg-[#74E3B6]/25 text-[#0B9E6B] border-[#74E3B6] font-bold",
        success:
          "bg-emerald-50 text-emerald-800 border-emerald-200 font-medium",
        warning:
          "bg-amber-50 text-amber-800 border-amber-200 font-medium",
        destructive:
          "bg-red-50 text-red-800 border-red-200 font-medium",
        dark:
          "bg-[#0F2A21] text-white border-[#163a2e] font-medium",
      },
      size: {
        default: "px-3 py-1 text-xs",
        sm: "px-2.5 py-0.5 text-[11px]",
        lg: "px-4 py-1.5 text-sm",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

function Badge({
  className,
  variant = "default",
  size = "default",
  asChild = false,
  ...props
}: React.ComponentProps<"span"> &
  VariantProps<typeof badgeVariants> & { asChild?: boolean }) {
  const Comp = asChild ? Slot.Root : "span"

  return (
    <Comp
      data-slot="badge"
      data-variant={variant}
      className={cn(badgeVariants({ variant, size }), className)}
      {...props}
    />
  )
}

export { Badge, badgeVariants }
