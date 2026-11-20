import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"
import { Slot } from "radix-ui"

import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex shrink-0 items-center justify-center rounded-full font-semibold transition-all duration-200 outline-none select-none cursor-pointer disabled:pointer-events-none disabled:opacity-50 active:scale-[0.98] [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 gap-2",
  {
    variants: {
      variant: {
        default:
          "bg-[#74E3B6] text-[#0D1F18] font-bold hover:bg-[#5fd4a5] hover:-translate-y-0.5 hover:shadow-[0_8px_20px_-4px_rgba(116,227,182,0.5)] active:translate-y-0 border border-transparent",
        outline:
          "border border-[#BFE3D2] bg-white text-[#0D1F18] hover:bg-[#EAFBF3] hover:border-[#74E3B6] hover:-translate-y-0.5 active:translate-y-0 shadow-xs",
        secondary:
          "bg-[#EAFBF3] text-[#0D1F18] border border-[#BFE3D2]/60 hover:bg-[#D4F6E6] hover:border-[#74E3B6]",
        ghost:
          "hover:bg-[#EAFBF3] text-[#3F5F52] hover:text-[#0D1F18]",
        destructive:
          "bg-red-50 text-red-600 border border-red-200 hover:bg-red-100",
        mint:
          "bg-[#74E3B6] text-[#0D1F18] font-bold shadow-[0_10px_25px_-5px_rgba(116,227,182,0.4)] hover:shadow-lg hover:-translate-y-0.5 active:translate-y-0",
        dark:
          "bg-[#0F2A21] text-white hover:bg-[#163a2e] shadow-sm hover:-translate-y-0.5 active:translate-y-0",
        link: "text-[#0B9E6B] underline underline-offset-4 hover:underline",
      },
      size: {
        default: "h-11 px-6 text-sm",
        xs: "h-7 px-3 text-xs gap-1 [&_svg:not([class*='size-'])]:size-3",
        sm: "h-9 px-4 text-xs gap-1.5",
        lg: "h-14 px-8 text-base font-bold",
        icon: "size-10",
        "icon-xs": "size-7 [&_svg:not([class*='size-'])]:size-3",
        "icon-sm": "size-9",
        "icon-lg": "size-12",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

function Button({
  className,
  variant = "default",
  size = "default",
  asChild = false,
  ...props
}: React.ComponentProps<"button"> &
  VariantProps<typeof buttonVariants> & {
    asChild?: boolean
  }) {
  const Comp = asChild ? Slot.Root : "button"

  return (
    <Comp
      data-slot="button"
      data-variant={variant}
      data-size={size}
      className={cn(buttonVariants({ variant, size, className }))}
      {...props}
    />
  )
}

export { Button, buttonVariants }
