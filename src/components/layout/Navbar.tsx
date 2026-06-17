'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { useEffect, useState, useCallback, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Wallet, LogOut, LayoutDashboard, ClipboardList } from 'lucide-react'
import { ethers, type Eip1193Provider } from 'ethers'

interface UserProfile {
  id: string;
  role: string | null;
}

interface WindowWithEthereum extends Window {
  ethereum?: Eip1193Provider;
}

export function Navbar() {
  const pathname = usePathname()
  const [user, setUser] = useState<{ id: string; email?: string } | null>(null)
  const [role, setRole] = useState<string | null>(null)
  const [address, setAddress] = useState<string | null>(null)
  const supabase = useMemo(() => createClient(), [])

  const checkWallet = useCallback(async () => {
    const win = window as unknown as WindowWithEthereum
    if (typeof window !== 'undefined' && win.ethereum) {
      try {
        const provider = new ethers.BrowserProvider(win.ethereum)
        const accounts = await provider.listAccounts()
        if (accounts.length > 0) {
          setAddress(accounts[0].address)
        }
      } catch (e) {
        console.error("Error checking wallet", e)
      }
    }
  }, [])

  useEffect(() => {
    const getUser = async () => {
      const { data: { user: authUser } } = await supabase.auth.getUser()
      if (authUser) {
        setUser({ id: authUser.id, email: authUser.email })
        const { data: profile } = await supabase
          .from('users')
          .select('role')
          .eq('id', authUser.id)
          .single() as { data: UserProfile | null }
        setRole(profile?.role || null)
      }
    }
    getUser()
  }, [supabase])

  useEffect(() => {
    const timer = setTimeout(() => {
        checkWallet()
    }, 100)
    return () => clearTimeout(timer)
  }, [checkWallet])

  const connectWallet = async () => {
    const win = window as unknown as WindowWithEthereum
    if (typeof window === 'undefined' || !win.ethereum) {
      alert("Please install MiniPay or MetaMask")
      return
    }
    try {
      const accounts = await win.ethereum.request({ method: 'eth_requestAccounts' }) as string[]
      if (accounts && accounts.length > 0) {
        setAddress(accounts[0])
      }
    } catch (e) {
      console.error("Error connecting wallet", e)
    }
  }

  const truncateAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`
  }

  return (
    <nav className="sticky top-0 z-50 w-full border-b bg-background/80 backdrop-blur-md">
      <div className="container flex h-16 items-center justify-between px-4 md:px-8 mx-auto">
        <div className="flex items-center gap-8 text-left">
          <Link href="/" className="flex items-center space-x-2 text-left">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <span className="text-primary-foreground font-bold text-xl leading-none">D</span>
            </div>
            <span className="hidden md:inline-block font-bold text-xl tracking-tight leading-none">DataMint</span>
          </Link>

          {user && (
            <div className="hidden md:flex items-center gap-1 text-left">
              {role === 'creator' && (
                <Link href="/dashboard">
                  <Button variant={pathname === '/dashboard' ? 'secondary' : 'ghost'} className="rounded-full h-10">
                    <LayoutDashboard className="w-4 h-4 mr-2" />
                    Dashboard
                  </Button>
                </Link>
              )}
              {role === 'contributor' && (
                <Link href="/tasks">
                  <Button variant={pathname === '/tasks' ? 'secondary' : 'ghost'} className="rounded-full h-10">
                    <ClipboardList className="w-4 h-4 mr-2" />
                    Available Tasks
                  </Button>
                </Link>
              )}
            </div>
          )}
        </div>

        <div className="flex items-center gap-3 text-left h-10">
          {address ? (
            <Button variant="outline" className="rounded-full border-primary/20 bg-primary/5 hover:bg-primary/10 transition-all text-sm font-medium h-10 px-4">
              <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse mr-2" />
              {truncateAddress(address)}
            </Button>
          ) : (
            <Button
              variant="outline"
              className="rounded-full border-primary text-primary hover:bg-primary hover:text-primary-foreground transition-all h-10 px-4"
              onClick={connectWallet}
            >
              <Wallet className="w-4 h-4 mr-2" />
              Connect Wallet
            </Button>
          )}

          {!user ? (
            <Link href="/login">
              <Button className="rounded-full px-6 bg-primary text-primary-foreground hover:opacity-90 h-10 font-bold">
                Sign In
              </Button>
            </Link>
          ) : (
            <div className="flex items-center gap-2 ml-2 pl-2 border-l h-10">
              <Button
                variant="ghost"
                size="icon"
                className="rounded-full hover:bg-destructive/10 hover:text-destructive w-10 h-10"
                onClick={async () => {
                  await supabase.auth.signOut()
                  window.location.href = '/'
                }}
              >
                <LogOut className="w-5 h-5" />
              </Button>
            </div>
          )}
        </div>
      </div>
    </nav>
  )
}
