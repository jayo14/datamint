'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Wallet, ArrowRight, ShieldCheck } from 'lucide-react'

interface EthereumProvider {
  request: (args: { method: string; params?: unknown[] }) => Promise<string[]>;
}

interface WindowWithEthereum extends Window {
  ethereum?: EthereumProvider;
}

export default function Login() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [walletLoading, setWalletLoading] = useState(false)
  const [role, setRole] = useState<'creator' | 'contributor'>('contributor')
  const supabase = createClient()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    document.cookie = `datamint_intended_role=${role}; path=/; max-age=3600`

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback`,
      },
    })

    if (error) {
      alert(error.message)
    } else {
      alert('Check your email for the login link!')
    }
    setLoading(false)
  }

  const handleWalletConnect = async () => {
    const win = window as unknown as WindowWithEthereum
    if (typeof window !== 'undefined' && !win.ethereum) {
      alert("Please install MiniPay or MetaMask")
      return
    }

    setWalletLoading(true)
    try {
      if (win.ethereum) {
        const accounts = await win.ethereum.request({ method: 'eth_requestAccounts' })
        const address = accounts[0]

        document.cookie = `datamint_intended_role=${role}; path=/; max-age=3600`
        document.cookie = `datamint_wallet_address=${address}; path=/; max-age=3600`

        const emailForWallet = `${address.toLowerCase()}@datamint.io`

        const { error } = await supabase.auth.signInWithOtp({
          email: emailForWallet,
          options: {
            emailRedirectTo: `${window.location.origin}/auth/callback`,
          },
        })

        if (error) throw error

        alert("Wallet linked! Since we use email-based auth for security, we've sent a verification link to your temporary wallet-linked identity. Check your dashboard soon!")
      }
    } catch (error: unknown) {
      console.error(error)
      const message = error instanceof Error ? error.message : String(error)
      alert("Connection failed: " + message)
    } finally {
      setWalletLoading(false)
    }
  }

  return (
    <div className="flex flex-col items-center justify-center min-h-[calc(100vh-10rem)] px-4 text-left">
      <div className="w-full max-w-xl space-y-8 text-left">
        <div className="text-center space-y-2 text-left">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 border border-primary/20 text-primary-foreground text-xs font-bold uppercase tracking-wider mb-4 mx-auto">
                <ShieldCheck className="w-3 h-3" />
                <span>Secure Authentication</span>
            </div>
            <h1 className="text-4xl font-black tracking-tight text-center leading-tight">Welcome to DataMint</h1>
            <p className="text-muted-foreground text-lg text-center leading-relaxed">Join the decentralized data revolution.</p>
        </div>

        <Card className="border-none shadow-2xl rounded-[2.5rem] overflow-hidden text-left bg-white">
          <div className="grid md:grid-cols-1 gap-0 text-left">
            <div className="p-8 md:p-12 text-left">
                <div className="space-y-6 text-left">
                    <div className="space-y-2 text-center text-left">
                        <Label className="text-base font-bold text-left block text-center">First, select your journey:</Label>
                        <div className="grid grid-cols-2 gap-4 p-1 bg-secondary rounded-2xl">
                            <button
                                type="button"
                                className={`py-3 rounded-xl font-bold text-sm transition-all ${role === 'contributor' ? 'bg-white shadow-sm text-primary-foreground' : 'text-muted-foreground hover:text-foreground'}`}
                                onClick={() => setRole('contributor')}
                            >
                                Contributor
                            </button>
                            <button
                                type="button"
                                className={`py-3 rounded-xl font-bold text-sm transition-all ${role === 'creator' ? 'bg-white shadow-sm text-primary-foreground' : 'text-muted-foreground hover:text-foreground'}`}
                                onClick={() => setRole('creator')}
                            >
                                Creator
                            </button>
                        </div>
                    </div>

                    <div className="space-y-4 text-left">
                        <Button
                            variant="outline"
                            className="w-full h-14 rounded-2xl border-2 hover:bg-secondary flex items-center justify-center gap-3 text-lg font-bold transition-all h-14"
                            onClick={handleWalletConnect}
                            disabled={walletLoading}
                        >
                            <Wallet className="w-6 h-6 text-primary-foreground" />
                            {walletLoading ? 'Connecting...' : 'Continue with Wallet'}
                        </Button>

                        <div className="relative text-left">
                            <div className="absolute inset-0 flex items-center">
                                <span className="w-full border-t" />
                            </div>
                            <div className="relative flex justify-center text-xs uppercase">
                                <span className="bg-white px-4 text-muted-foreground font-bold leading-none">Or use email</span>
                            </div>
                        </div>

                        <form onSubmit={handleLogin} className="space-y-4 text-left">
                            <div className="space-y-2 text-left">
                                <Input
                                    id="email"
                                    type="email"
                                    placeholder="name@example.com"
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                    required
                                    className="h-14 rounded-2xl bg-secondary/50 border-none px-6 text-lg focus-visible:ring-primary h-14 text-base"
                                />
                            </div>
                            <Button type="submit" className="w-full h-14 rounded-2xl text-lg font-bold shadow-lg shadow-primary/20 h-14 bg-primary text-primary-foreground hover:opacity-90" disabled={loading}>
                                {loading ? 'Sending link...' : (
                                    <span className="flex items-center gap-2 leading-none">
                                        Send Magic Link
                                        <ArrowRight className="w-5 h-5" />
                                    </span>
                                )}
                            </Button>
                        </form>
                    </div>
                </div>
            </div>
          </div>
        </Card>

        <p className="text-center text-sm text-muted-foreground text-center">
            By continuing, you agree to DataMint&apos;s <br />
            <span className="text-foreground font-semibold underline cursor-pointer">Terms of Service</span> and <span className="text-foreground font-semibold underline cursor-pointer">Privacy Policy</span>.
        </p>
      </div>
    </div>
  )
}
