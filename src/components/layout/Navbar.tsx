'use client'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Wallet, LogOut, LayoutDashboard, ClipboardList } from 'lucide-react'
import { useWeb3 } from '@/hooks/useWeb3'

export function Navbar() {
  const pathname = usePathname()
  const [user, setUser] = useState<{ id: string } | null>(null)
  const [role, setRole] = useState<string | null>(null)
  const supabase = useMemo(() => createClient(), [])
  const { address, connect, isConnected, isConnecting } = useWeb3()

  useEffect(() => {
    const getUser = async () => {
      const { data: { user: authUser } } = await supabase.auth.getUser()
      if (authUser) {
        setUser({ id: authUser.id })
        const { data: profile } = await supabase.from('users').select('role').eq('id', authUser.id).single()
        setRole(profile?.role || null)
      }
    }
    getUser()
  }, [supabase])

  const truncateAddress = (addr: string) => `${addr.slice(0, 6)}...${addr.slice(-4)}`

  return (
    <nav className="sticky top-0 z-50 w-full border-b bg-background/80 backdrop-blur-md">
      <div className="container flex h-16 items-center justify-between px-4 md:px-8 mx-auto">
        <div className="flex items-center gap-8">
          <Link href="/" className="flex items-center space-x-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center"><span className="text-primary-foreground font-bold text-xl">D</span></div>
            <span className="hidden md:inline-block font-bold text-xl">DataMint</span>
          </Link>
          {user && (
            <div className="hidden md:flex items-center gap-1">
              {role === 'creator' && <Link href="/dashboard"><Button variant={pathname === '/dashboard' ? 'secondary' : 'ghost'} className="rounded-full h-10"><LayoutDashboard className="w-4 h-4 mr-2" />Dashboard</Button></Link>}
              {role === 'contributor' && <Link href="/tasks"><Button variant={pathname === '/tasks' ? 'secondary' : 'ghost'} className="rounded-full h-10"><ClipboardList className="w-4 h-4 mr-2" />Available Tasks</Button></Link>}
            </div>
          )}
        </div>
        <div className="flex items-center gap-3">
          {isConnected ? <Button variant="outline" className="rounded-full border-primary/20 bg-primary/5 h-10 px-4"><div className="w-2 h-2 rounded-full bg-green-500 mr-2" />{truncateAddress(address!)}</Button> : <Button variant="outline" className="rounded-full border-primary text-primary h-10 px-4" onClick={connect} disabled={isConnecting}><Wallet className="w-4 h-4 mr-2" />{isConnecting ? 'Connecting...' : 'Connect Wallet'}</Button>}
          {!user ? <Link href="/login"><Button className="rounded-full px-6 bg-primary text-primary-foreground h-10 font-bold">Sign In</Button></Link> : <Button variant="ghost" size="icon" className="rounded-full w-10 h-10" onClick={async () => { await supabase.auth.signOut(); window.location.href = '/' }}><LogOut className="w-5 h-5" /></Button>}
        </div>
      </div>
    </nav>
  )
}
