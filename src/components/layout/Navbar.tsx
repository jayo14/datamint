'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useWeb3 } from '@/hooks/useWeb3'

export function Navbar() {
  const pathname = usePathname()
  const [user, setUser] = useState<{ id: string; email?: string } | null>(null)
  const [role, setRole] = useState<'creator' | 'contributor' | null>(null)
  const supabase = useMemo(() => createClient(), [])
  const { address, connect, isConnected, isConnecting } = useWeb3()

  useEffect(() => {
    const getUser = async () => {
      const {
        data: { user: authUser },
      } = await supabase.auth.getUser()
      if (authUser) {
        setUser({ id: authUser.id, email: authUser.email })
        const { data: profile } = await supabase
          .from('users')
          .select('role')
          .eq('id', authUser.id)
          .single()
        setRole(profile?.role || null)
      }
    }
    getUser()
  }, [supabase])

  const truncateAddress = (addr: string) => `${addr.slice(0, 6)}...${addr.slice(-4)}`

  return (
    <header className="sticky top-0 z-40 w-full pt-3 px-4 sm:px-6 lg:px-8 pointer-events-none">
      <div className="max-w-7xl mx-auto flex items-center justify-between gap-4 pointer-events-auto">
        {/* Brand Logo */}
        <Link
          href="/"
          className="flex items-center gap-2.5 font-bricolage text-2xl font-bold tracking-tight text-[#0D1F18] transition-transform hover:scale-105"
        >
          <div className="w-10 h-10 rounded-[14px] bg-[#74E3B6] text-[#0D1F18] flex items-center justify-center font-bold text-xl shadow-xs">
            D
          </div>
          <span className="hidden sm:inline">datamint</span>
        </Link>

        {/* Center Pill Navigation */}
        <nav
          aria-label="Dashboard Navigation"
          className="flex items-center gap-1.5 p-1.5 rounded-full bg-white/90 backdrop-blur-md border border-[#BFE3D2] shadow-sm"
        >
          <Link href="/dashboard">
            <Button
              variant={pathname === '/dashboard' ? 'default' : 'ghost'}
              size="sm"
              className={pathname === '/dashboard' ? 'font-bold' : 'text-[#3F5F52] hover:text-[#0D1F18]'}
            >
              <span className="material-symbols-rounded text-lg">dashboard</span>
              <span className="hidden md:inline">Dashboard</span>
            </Button>
          </Link>

          <Link href="/tasks">
            <Button
              variant={pathname === '/tasks' ? 'default' : 'ghost'}
              size="sm"
              className={pathname === '/tasks' ? 'font-bold' : 'text-[#3F5F52] hover:text-[#0D1F18]'}
            >
              <span className="material-symbols-rounded text-lg">task_alt</span>
              <span className="hidden md:inline">Tasks</span>
            </Button>
          </Link>

          <Link href="/dashboard/register-agent">
            <Button
              variant={pathname === '/dashboard/register-agent' ? 'default' : 'ghost'}
              size="sm"
              className={pathname === '/dashboard/register-agent' ? 'font-bold' : 'text-[#3F5F52] hover:text-[#0D1F18]'}
            >
              <span className="material-symbols-rounded text-lg">smart_toy</span>
              <span className="hidden lg:inline">ERC-8004 Agent</span>
            </Button>
          </Link>
        </nav>

        {/* Right Actions: Wallet & User */}
        <div className="flex items-center gap-2.5">
          {role && (
            <Badge
              variant="secondary"
              className="hidden xl:inline-flex uppercase tracking-wider text-[10px] font-bold py-1 px-3"
            >
              <span className="w-1.5 h-1.5 rounded-full bg-[#0B9E6B] mr-1" />
              {role}
            </Badge>
          )}

          {isConnected ? (
            <Button
              variant="outline"
              size="sm"
              className="bg-white/90 border-[#BFE3D2] text-[#0D1F18] font-mono font-medium shadow-xs"
            >
              <span className="w-2 h-2 rounded-full bg-[#0B9E6B] animate-pulse" />
              {truncateAddress(address!)}
            </Button>
          ) : (
            <Button
              variant="outline"
              size="sm"
              onClick={connect}
              disabled={isConnecting}
              className="bg-white border-[#BFE3D2] text-[#0D1F18] hover:border-[#74E3B6]"
            >
              <span className="material-symbols-rounded text-lg text-[#0B9E6B]">
                account_balance_wallet
              </span>
              <span className="hidden sm:inline">
                {isConnecting ? 'Connecting...' : 'Connect Wallet'}
              </span>
            </Button>
          )}

          {!user ? (
            <Link href="/login">
              <Button size="sm" className="font-bold">
                <span className="material-symbols-rounded text-lg">login</span>
                Sign In
              </Button>
            </Link>
          ) : (
            <Button
              variant="outline"
              size="icon-sm"
              className="bg-white border-[#BFE3D2] text-[#3F5F52] hover:text-red-600 hover:border-red-200"
              title="Sign Out"
              onClick={async () => {
                await supabase.auth.signOut()
                window.location.href = '/'
              }}
            >
              <span className="material-symbols-rounded text-lg">logout</span>
              <span className="sr-only">Sign out</span>
            </Button>
          )}
        </div>
      </div>
    </header>
  )
}
