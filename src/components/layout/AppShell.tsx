'use client'

import { usePathname } from 'next/navigation'
import { Navbar } from '@/components/layout/Navbar'

interface AppShellProps {
  children: React.ReactNode
}

export function AppShell({ children }: AppShellProps) {
  const pathname = usePathname()
  const isLanding = pathname === '/'
  const isAuth =
    pathname === '/login' ||
    pathname === '/onboarding' ||
    pathname.startsWith('/auth')

  if (isLanding || isAuth) {
    return <main className="min-h-screen w-full">{children}</main>
  }

  return (
    <div className="relative min-h-screen flex flex-col bg-[#EAFBF3] text-[#0D1F18] overflow-x-hidden selection:bg-[#74E3B6] selection:text-[#0D1F18]">
      {/* Ambient background glowing circles matching landing/auth design */}
      <div
        className="pointer-events-none fixed -top-24 -left-24 w-96 h-96 rounded-full bg-[#74E3B6] opacity-30 blur-3xl"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none fixed top-1/3 -right-32 w-[30rem] h-[30rem] rounded-full bg-[#FFE08A] opacity-25 blur-3xl"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none fixed -bottom-24 left-1/4 w-[28rem] h-[28rem] rounded-full bg-[#5FD6E8] opacity-20 blur-3xl"
        aria-hidden="true"
      />

      <Navbar />

      <main className="flex-1 relative z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-10">
          {children}
        </div>
      </main>
    </div>
  )
}
