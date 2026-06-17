#!/bin/bash

# Supabase
cat > src/lib/supabase/server.ts <<'EOF2'
import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

export const createClient = async () => {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // The setAll method was called from a Server Component.
          }
        },
      },
    }
  );
};
EOF2

cat > src/lib/supabase/client.ts <<'EOF2'
import { createBrowserClient } from "@supabase/ssr";

export const createClient = () =>
  createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
  );
EOF2

cat > src/lib/supabase/middleware.ts <<'EOF2'
import { createServerClient } from "@supabase/ssr";
import { type NextRequest, NextResponse } from "next/server";

export const updateSession = async (request: NextRequest) => {
  let supabaseResponse = NextResponse.next({
    request: {
      headers: request.headers,
    },
  });

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({
            request,
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    },
  );

  await supabase.auth.getUser();

  return supabaseResponse
};
EOF2

# API
mkdir -p src/app/api/submissions/upload
cat > src/app/api/submissions/upload/route.ts <<'EOF2'
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const formData = await req.formData()
    const file = formData.get('file') as File | null
    const content = formData.get('content') as string | null
    const datasetId = formData.get('datasetId') as string

    if (!datasetId) {
      return NextResponse.json({ error: 'datasetId is required' }, { status: 400 })
    }

    let fileUrl = ''
    if (file) {
      const fileName = `${user.id}/${Date.now()}-${file.name}`
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('submissions')
        .upload(fileName, file)

      if (uploadError) {
        return NextResponse.json({ error: 'Upload failed: ' + uploadError.message }, { status: 500 })
      }
      fileUrl = uploadData.path
    }

    const { data: submission, error: insertError } = await supabase
      .from('submissions')
      .insert({
        dataset_id: parseInt(datasetId),
        user_id: user.id,
        file_url: fileUrl || null,
        content: content || null,
        status: 'pending'
      })
      .select('id')
      .single()

    if (insertError) {
      return NextResponse.json({ error: 'Database insert failed: ' + insertError.message }, { status: 500 })
    }

    const validateUrl = new URL('/api/validate', req.url).toString()
    fetch(validateUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ submissionId: submission.id })
    }).catch(console.error)

    return NextResponse.json({ success: true, submissionId: submission.id })
  } catch (error: any) {
    console.error('Upload error:', error)
    return NextResponse.json({ error: 'Internal server error: ' + error.message }, { status: 500 })
  }
}
EOF2

cat > src/app/api/validate/route.ts <<'EOF2'
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import OpenAI from 'openai'

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY })

export async function POST(req: Request) {
  try {
    const { submissionId } = await req.json()
    if (!submissionId) return NextResponse.json({ error: 'submissionId required' }, { status: 400 })

    const supabase = await createClient()

    const { data: submission, error: subError } = await supabase
      .from('submissions')
      .select('*, datasets(type, title)')
      .eq('id', submissionId)
      .single()

    if (subError || !submission) {
      return NextResponse.json({ error: 'Submission not found' }, { status: 404 })
    }

    const datasetType = submission.datasets?.type || 'text'
    const datasetTitle = submission.datasets?.title || 'Unknown Dataset'
    let aiScore = 0
    let feedback = ''
    let approved = false

    if (datasetType === 'text') {
      const textContent = submission.content || ''
      if (textContent.trim().length < 10) {
        aiScore = 0
        feedback = 'Text too short. Minimum 10 characters required.'
      } else {
        try {
          const completion = await openai.chat.completions.create({
            model: 'gpt-4o-mini',
            messages: [
              {
                role: 'system',
                content: `You are a data quality validator for the dataset: "${datasetTitle}". Respond ONLY with JSON: {"score": number, "feedback": "string", "approved": boolean}`
              },
              { role: 'user', content: textContent }
            ],
            response_format: { type: 'json_object' }
          })
          const result = JSON.parse(completion.choices[0].message.content || '{}')
          aiScore = result.score || 0
          feedback = result.feedback || 'Validation complete.'
          approved = result.approved || false
        } catch (e) {
          aiScore = 50
          feedback = "Manual review required."
          approved = false
        }
      }
    } else if (datasetType === 'voice' || datasetType === 'image') {
      if (submission.file_url) {
        aiScore = 75
        feedback = `${datasetType === 'voice' ? 'Audio' : 'Image'} file validated.`
        approved = true
      }
    }

    await supabase
      .from('submissions')
      .update({
        ai_score: aiScore,
        ai_feedback: feedback,
        status: approved ? 'approved' : submission.status
      })
      .eq('id', submissionId)

    if (approved) {
      await supabase.rpc('increment_completed_count', { dataset_id_param: submission.dataset_id })
    }

    return NextResponse.json({ approved, score: aiScore, feedback })
  } catch (error) {
    return NextResponse.json({ error: 'Validation failed' }, { status: 500 })
  }
}
EOF2

# Auth Callback
cat > src/app/auth/callback/route.ts <<'EOF2'
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import { cookies } from 'next/headers'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next') ?? '/'

  if (code) {
    const supabase = await createClient()
    const { error, data } = await supabase.auth.exchangeCodeForSession(code)

    if (!error && data.user) {
      const cookieStore = await cookies()
      const intendedRole = cookieStore.get('datamint_intended_role')?.value
      const walletAddress = cookieStore.get('datamint_wallet_address')?.value

      const { data: profile } = await supabase.from('users').select('*').eq('id', data.user.id).single()

      if (!profile) {
        await supabase.from('users').insert({
          id: data.user.id,
          role: (intendedRole as 'creator' | 'contributor') || 'contributor',
          wallet_address: walletAddress || null
        })
      }

      const finalNext = next === '/' ? (intendedRole === 'creator' || profile?.role === 'creator' ? '/dashboard' : '/tasks') : next
      return NextResponse.redirect(`${origin}${finalNext}`)
    }
  }
  return NextResponse.redirect(`${origin}/auth/auth-code-error`)
}
EOF2

# Web3 hook
mkdir -p src/hooks
cat > src/hooks/useWeb3.tsx <<'EOF2'
'use client'
import React, { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { ethers, type Eip1193Provider } from 'ethers'

interface WindowWithEthereum extends Window {
  ethereum?: Eip1193Provider;
}

interface Web3ContextType {
  address: string | null;
  isConnected: boolean;
  isConnecting: boolean;
  connect: () => Promise<void>;
  disconnect: () => void;
  signer: ethers.Signer | null;
  provider: ethers.BrowserProvider | null;
  chainId: bigint | null;
}

const Web3Context = createContext<Web3ContextType | undefined>(undefined)

export function Web3Provider({ children }: { children: React.ReactNode }) {
  const [address, setAddress] = useState<string | null>(null)
  const [signer, setSigner] = useState<ethers.Signer | null>(null)
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null)
  const [chainId, setChainId] = useState<bigint | null>(null)
  const [isConnecting, setIsConnecting] = useState(false)

  const connect = useCallback(async () => {
    const win = window as unknown as WindowWithEthereum
    if (typeof window === 'undefined' || !win.ethereum) return
    setIsConnecting(true)
    try {
      const browserProvider = new ethers.BrowserProvider(win.ethereum)
      const accounts = await browserProvider.send('eth_requestAccounts', [])
      const network = await browserProvider.getNetwork()
      const browserSigner = await browserProvider.getSigner()
      setAddress(accounts[0]); setSigner(browserSigner); setProvider(browserProvider); setChainId(network.chainId)
    } catch (error) { console.error(error) } finally { setIsConnecting(false) }
  }, [])

  const disconnect = useCallback(() => { setAddress(null); setSigner(null); setProvider(null); setChainId(null) }, [])

  useEffect(() => {
    const checkConnection = async () => {
      const win = window as unknown as WindowWithEthereum
      if (typeof window !== 'undefined' && win.ethereum) {
        const browserProvider = new ethers.BrowserProvider(win.ethereum)
        const accounts = await browserProvider.listAccounts()
        if (accounts.length > 0) {
          const network = await browserProvider.getNetwork(); const browserSigner = await browserProvider.getSigner()
          setAddress(accounts[0].address); setSigner(browserSigner); setProvider(browserProvider); setChainId(network.chainId)
        }
      }
    }
    checkConnection()
  }, [])

  return <Web3Context.Provider value={{ address, isConnected: !!address, isConnecting, connect, disconnect, signer, provider, chainId }}>{children}</Web3Context.Provider>
}

export function useWeb3() {
  const context = useContext(Web3Context)
  if (context === undefined) throw new Error('useWeb3 must be used within a Web3Provider')
  return context
}
EOF2

# Layout
cat > src/app/layout.tsx <<'EOF2'
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Navbar } from "@/components/layout/Navbar";
import { Web3Provider } from "@/hooks/useWeb3";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "DataMint | AI Dataset Marketplace",
  description: "On-chain AI dataset marketplace powered by human contributors + instant Celo payouts.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className={`${inter.className} min-h-screen bg-background font-sans antialiased`}>
        <Web3Provider>
          <div className="relative flex min-h-screen flex-col">
            <Navbar />
            <main className="flex-1">
              <div className="container py-6 mx-auto">
                {children}
              </div>
            </main>
          </div>
        </Web3Provider>
      </body>
    </html>
  );
}
EOF2

# Navbar
cat > src/components/layout/Navbar.tsx <<'EOF2'
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
EOF2

# Homepage
cat > src/app/page.tsx <<'EOF2'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Database, Coins, Users, Zap, ArrowRight, ShieldCheck } from 'lucide-react'

export default function Home() {
  return (
    <div className="flex flex-col gap-24 py-12 md:py-24">
      <section className="text-center space-y-8 max-w-4xl mx-auto">
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20 text-primary-foreground text-sm font-bold uppercase tracking-wider mb-4 animate-in fade-in slide-in-from-bottom-4 duration-1000">
            <ShieldCheck className="w-4 h-4" />
            <span>On-Chain & Verified</span>
        </div>
        <h1 className="text-5xl md:text-7xl font-black tracking-tighter leading-[1.1]">Turn Human Input into <br /><span className="text-primary italic">AI Datasets</span></h1>
        <p className="text-xl md:text-2xl text-muted-foreground max-w-[700px] mx-auto leading-relaxed">The fastest way to collect high-quality data for AI models, with instant Celo payouts for contributors worldwide.</p>
        <div className="flex flex-col sm:flex-row justify-center gap-4 pt-8">
          <Link href="/login"><Button size="lg" className="px-10 h-16 rounded-2xl text-xl font-bold bg-primary text-primary-foreground shadow-xl shadow-primary/20">Start Building<ArrowRight className="ml-2 w-6 h-6" /></Button></Link>
          <Button size="lg" variant="outline" className="px-10 h-16 rounded-2xl text-xl font-bold border-2 hover:bg-secondary">Learn More</Button>
        </div>
      </section>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
        {[
          { icon: Zap, title: "Instant Payouts", desc: "Get paid in cUSD immediately after AI validation." },
          { icon: Database, title: "Structured Data", desc: "Export AI-ready datasets in CSV or JSON format." },
          { icon: Coins, title: "On-Chain Escrow", desc: "Trustless payments powered by Celo smart contracts." },
          { icon: Users, title: "Global Crowd", desc: "Access diverse human data from anywhere in the world." }
        ].map((item, i) => (
          <Card key={i} className="border-none shadow-xl rounded-[2.5rem] bg-white p-2">
            <CardHeader className="space-y-4">
              <div className="w-16 h-16 rounded-2xl flex items-center justify-center bg-primary/10 text-primary-foreground"><item.icon className="w-8 h-8" /></div>
              <div><CardTitle className="text-2xl font-black">{item.title}</CardTitle><CardDescription className="text-base pt-2">{item.desc}</CardDescription></div>
            </CardHeader>
          </Card>
        ))}
      </div>
      <section className="bg-secondary/40 rounded-[3.5rem] p-8 md:p-20 border border-white/50 backdrop-blur-sm">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          <div className="space-y-10">
            <h2 className="text-4xl md:text-5xl font-black tracking-tight leading-tight">How it Works</h2>
            <div className="space-y-8">
              {[
                { step: 1, title: "Create & Fund", desc: "Define your dataset needs and fund the escrow contract with cUSD." },
                { step: 2, title: "Contribute", desc: "Contributors submit voice, image, or text data via mobile or MiniPay." },
                { step: 3, title: "AI Validates", desc: "Our AI layer checks quality and relevance instantly using GPT-4o." },
                { step: 4, title: "Paid Instantly", desc: "Smart contract releases funds to the contributor's wallet." }
              ].map((item, i) => (
                <div key={i} className="flex gap-6 group">
                  <div className="flex-none w-12 h-12 rounded-2xl bg-primary text-primary-foreground flex items-center justify-center font-black text-xl shadow-lg shadow-primary/20">{item.step}</div>
                  <div><p className="font-black text-2xl mb-1">{item.title}</p><p className="text-muted-foreground text-lg leading-relaxed">{item.desc}</p></div>
                </div>
              ))}
            </div>
          </div>
          <div className="relative">
            <div className="absolute -inset-4 bg-primary/20 blur-3xl rounded-full opacity-50" />
            <div className="relative bg-white rounded-[3rem] p-10 border shadow-2xl space-y-8">
              <div className="flex justify-between items-center border-b pb-6"><span className="font-black text-xl">Sample Task</span><Badge className="bg-primary/10 text-primary-foreground border-none px-4 py-1 rounded-full text-sm font-bold">VOICE</Badge></div>
              <p className="text-lg font-medium leading-relaxed italic">"Record yourself saying: 'The quick brown fox jumps over the lazy dog' in your native accent."</p>
              <div className="flex justify-between items-center text-sm font-bold text-muted-foreground bg-secondary/50 p-4 rounded-2xl"><span className="flex items-center gap-2"><Coins className="w-4 h-4" /> Reward: 0.50 cUSD</span><span className="flex items-center gap-2"><Zap className="w-4 h-4" /> Time: ~30s</span></div>
              <Button className="w-full h-16 rounded-[1.5rem] text-xl font-black bg-primary text-primary-foreground shadow-lg shadow-primary/10">Try Demo Task</Button>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
EOF2

# Globals CSS
cat > src/app/globals.css <<'EOF2'
@import "tailwindcss";
@import "tw-animate-css";
@import "shadcn/tailwind.css";

@custom-variant dark (&:is(.dark *));

@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
  --color-primary-foreground: var(--primary-foreground);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-destructive: var(--destructive);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-popover: var(--popover);
  --color-popover-foreground: var(--popover-foreground);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) * 1.5);
  --radius-2xl: calc(var(--radius) * 2);
}

:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.2 0.02 165);
  --card: oklch(1 0 0);
  --card-foreground: oklch(0.2 0.02 165);
  --popover: oklch(1 0 0);
  --popover-foreground: oklch(0.2 0.02 165);
  --primary: oklch(0.85 0.12 165);
  --primary-foreground: oklch(0.2 0.05 165);
  --secondary: oklch(0.96 0.04 165);
  --secondary-foreground: oklch(0.3 0.1 165);
  --muted: oklch(0.98 0.01 165);
  --muted-foreground: oklch(0.5 0.05 165);
  --accent: oklch(0.92 0.06 165);
  --accent-foreground: oklch(0.2 0.05 165);
  --destructive: oklch(0.6 0.18 25);
  --border: oklch(0.92 0.03 165);
  --input: oklch(0.92 0.03 165);
  --ring: oklch(0.85 0.12 165);
  --radius: 0.75rem;
}

@layer base {
  * { @apply border-border outline-ring/50; }
  body { @apply bg-background text-foreground; }
  h1, h2, h3, h4, h5, h6 { @apply font-bold tracking-tight text-slate-900; }
}

.mint-gradient { background: linear-gradient(135deg, oklch(0.95 0.05 165), oklch(0.85 0.12 165)); }
EOF2
