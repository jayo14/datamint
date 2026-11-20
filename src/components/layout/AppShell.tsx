'use client'

import { usePathname } from 'next/navigation'
import { Navbar } from '@/components/layout/Navbar'

interface AppShellProps {
  children: React.ReactNode
}

export function AppShell({ children }: AppShellProps) {
  const pathname = usePathname()
  const isLanding = pathname === '/'
  const isAuth = pathname === '/login' || pathname === '/onboarding' || pathname.startsWith('/auth')

  if (isLanding || isAuth) {
    return <main className="min-h-screen w-full">{children}</main>
  }

  return (
    <div className="relative flex min-h-screen flex-col">
      <Navbar />
      <main className="flex-1">
        <div className="container py-6 mx-auto">
          {children}
        </div>
      </main>
    </div>
  )
}
