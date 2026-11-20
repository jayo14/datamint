import * as React from "react"

import { cn } from "@/lib/utils"

function Input({ className, type, ...props }: React.ComponentProps<"input">) {
  return (
    <input
      type={type}
      data-slot="input"
      className={cn(
        "h-12 w-full min-w-0 rounded-full border border-[#BFE3D2] bg-white px-5 py-2 text-sm text-[#0D1F18] transition-all duration-200 outline-none placeholder:text-[#3F5F52]/60 focus-visible:border-[#74E3B6] focus-visible:ring-2 focus-visible:ring-[#74E3B6]/30 disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-red-500",
        className
      )}
      {...props}
    />
  )
}

export { Input }
