import * as React from "react"

import { cn } from "@/lib/utils"

function Textarea({ className, ...props }: React.ComponentProps<"textarea">) {
  return (
    <textarea
      data-slot="textarea"
      className={cn(
        "flex min-h-[120px] w-full rounded-[24px] border border-[#BFE3D2] bg-white p-4 text-sm text-[#0D1F18] transition-all duration-200 outline-none placeholder:text-[#3F5F52]/60 focus-visible:border-[#74E3B6] focus-visible:ring-2 focus-visible:ring-[#74E3B6]/30 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-red-500 resize-y",
        className
      )}
      {...props}
    />
  )
}

export { Textarea }
