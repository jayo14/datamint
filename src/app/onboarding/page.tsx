'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardContent, CardDescription, CardFooter } from '@/components/ui/card'
import { CheckCircle2, UserCircle, Rocket, Coins, Sparkles, ArrowRight } from 'lucide-react'

interface UserProfile {
  id: string;
  role: 'creator' | 'contributor' | null;
  wallet_address?: string;
}

export default function Onboarding() {
  const [step, setStep] = useState(1)
  const [role, setRole] = useState<'creator' | 'contributor' | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [user, setUser] = useState<{ id: string; email?: string } | null>(null)
  const router = useRouter()
  const supabase = createClient()

  useEffect(() => {
    const checkUser = async () => {
      const { data: { user: authUser } } = await supabase.auth.getUser()
      if (!authUser) {
        router.push('/login')
        return
      }
      setUser({ id: authUser.id, email: authUser.email })

      const { data: profile } = await supabase
        .from('users')
        .select('role')
        .eq('id', authUser.id)
        .single() as { data: UserProfile | null }

      if (profile?.role) {
        setRole(profile.role)
      }
      setLoading(false)
    }
    checkUser()
  }, [router, supabase])

  const handleCompleteOnboarding = async () => {
    if (!role || !user) return
    setSaving(true)

    // Get wallet address from cookie if available
    const walletCookie = document.cookie
      .split('; ')
      .find(row => row.startsWith('datamint_wallet_address='))
    const walletAddress = walletCookie ? walletCookie.split('=')[1] : null

    const { error } = await supabase
      .from('users')
      .upsert({
        id: user.id,
        role: role,
        wallet_address: walletAddress
      })

    if (error) {
      alert(error.message)
    } else {
      router.push(role === 'creator' ? '/dashboard' : '/tasks')
    }
    setSaving(false)
  }

  if (loading) return (
    <div className="flex items-center justify-center min-h-[60vh]">
        <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin" />
    </div>
  )

  return (
    <div className="max-w-2xl mx-auto py-12 px-4 text-left">
      <div className="mb-12 text-center space-y-4 text-left">
        <div className="flex justify-center gap-2 text-left mx-auto">
            {[1, 2, 3].map((s) => (
                <div
                    key={s}
                    className={`h-2 w-16 rounded-full transition-all ${step >= s ? 'bg-primary' : 'bg-secondary'}`}
                />
            ))}
        </div>
        <h1 className="text-3xl font-black tracking-tight text-center">Complete your profile</h1>
        <p className="text-muted-foreground text-center text-base">Just a few steps to get you started on DataMint.</p>
      </div>

      {step === 1 && (
        <Card className="border-none shadow-xl rounded-[2.5rem] p-4 animate-in fade-in slide-in-from-right-4 duration-500 text-left bg-white">
            <CardHeader className="text-center text-left">
                <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mx-auto mb-4 text-primary-foreground">
                    <UserCircle className="w-10 h-10" />
                </div>
                <CardTitle className="text-2xl font-bold text-center">Choose your path</CardTitle>
                <CardDescription className="text-center text-base">How do you plan to use DataMint?</CardDescription>
            </CardHeader>
            <CardContent className="grid grid-cols-1 gap-4 pt-4 text-left">
                <button
                    onClick={() => setRole('creator')}
                    className={`flex items-start gap-4 p-6 rounded-3xl border-2 text-left transition-all ${role === 'creator' ? 'border-primary bg-primary/5' : 'border-border hover:border-primary/50'}`}
                >
                    <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${role === 'creator' ? 'bg-primary text-primary-foreground' : 'bg-secondary text-muted-foreground'}`}>
                        <Sparkles className="w-6 h-6" />
                    </div>
                    <div className="text-left">
                        <p className="font-bold text-lg text-left leading-tight">I am a Creator</p>
                        <p className="text-sm text-muted-foreground text-left pt-1">I want to request data and build AI models.</p>
                    </div>
                    {role === 'creator' && <CheckCircle2 className="ml-auto w-6 h-6 text-primary" />}
                </button>

                <button
                    onClick={() => setRole('contributor')}
                    className={`flex items-start gap-4 p-6 rounded-3xl border-2 text-left transition-all ${role === 'contributor' ? 'border-primary bg-primary/5' : 'border-border hover:border-primary/50'}`}
                >
                    <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${role === 'contributor' ? 'bg-primary text-primary-foreground' : 'bg-secondary text-muted-foreground'}`}>
                        <Coins className="w-6 h-6" />
                    </div>
                    <div className="text-left">
                        <p className="font-bold text-lg text-left leading-tight">I am a Contributor</p>
                        <p className="text-sm text-muted-foreground text-left pt-1">I want to earn rewards by completing tasks.</p>
                    </div>
                    {role === 'contributor' && <CheckCircle2 className="ml-auto w-6 h-6 text-primary" />}
                </button>
            </CardContent>
            <CardFooter className="pt-8 text-left">
                <Button
                    disabled={!role}
                    className="w-full h-14 rounded-2xl text-lg font-bold shadow-lg h-14 bg-primary text-primary-foreground hover:opacity-90"
                    onClick={() => setStep(2)}
                >
                    Continue
                </Button>
            </CardFooter>
        </Card>
      )}

      {step === 2 && (
        <Card className="border-none shadow-xl rounded-[2.5rem] p-4 animate-in fade-in slide-in-from-right-4 duration-500 text-left bg-white">
            <CardHeader className="text-center text-left">
                <div className="w-16 h-16 bg-primary/10 rounded-2xl flex items-center justify-center mx-auto mb-4 text-primary-foreground">
                    <Rocket className="w-10 h-10" />
                </div>
                <CardTitle className="text-2xl font-bold text-center leading-tight">Quick Overview</CardTitle>
                <CardDescription className="text-center text-base text-muted-foreground">Here is how it works for you.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6 pt-4 text-left">
                {role === 'creator' ? (
                    <div className="space-y-4 text-left">
                        <div className="flex gap-4 text-left">
                            <div className="w-8 h-8 rounded-full bg-primary/20 flex-none flex items-center justify-center font-bold text-primary-foreground text-sm">1</div>
                            <p className="text-muted-foreground font-medium pt-1 text-left text-base leading-relaxed">Create a dataset request and define task types.</p>
                        </div>
                        <div className="flex gap-4 text-left">
                            <div className="w-8 h-8 rounded-full bg-primary/20 flex-none flex items-center justify-center font-bold text-primary-foreground text-sm">2</div>
                            <p className="text-muted-foreground font-medium pt-1 text-left text-base leading-relaxed">Fund the on-chain escrow via Celo.</p>
                        </div>
                        <div className="flex gap-4 text-left">
                            <div className="w-8 h-8 rounded-full bg-primary/20 flex-none flex items-center justify-center font-bold text-primary-foreground text-sm">3</div>
                            <p className="text-muted-foreground font-medium pt-1 text-left text-base leading-relaxed">AI validates submissions and you export the data.</p>
                        </div>
                    </div>
                ) : (
                    <div className="space-y-4 text-left">
                        <div className="flex gap-4 text-left">
                            <div className="w-8 h-8 rounded-full bg-primary/20 flex-none flex items-center justify-center font-bold text-primary-foreground text-sm">1</div>
                            <p className="text-muted-foreground font-medium pt-1 text-left text-base leading-relaxed">Browse available tasks in your area.</p>
                        </div>
                        <div className="flex gap-4 text-left">
                            <div className="w-8 h-8 rounded-full bg-primary/20 flex-none flex items-center justify-center font-bold text-primary-foreground text-sm">2</div>
                            <p className="text-muted-foreground font-medium pt-1 text-left text-base leading-relaxed">Submit high-quality audio, images, or text.</p>
                        </div>
                        <div className="flex gap-4 text-left">
                            <div className="w-8 h-8 rounded-full bg-primary/20 flex-none flex items-center justify-center font-bold text-primary-foreground text-sm">3</div>
                            <p className="text-muted-foreground font-medium pt-1 text-left text-base leading-relaxed">Get paid instantly to your MiniPay wallet.</p>
                        </div>
                    </div>
                )}
            </CardContent>
            <CardFooter className="pt-8 flex gap-4 text-left">
                <Button variant="ghost" className="h-14 rounded-2xl flex-1 h-14 font-bold" onClick={() => setStep(1)}>Back</Button>
                <Button className="h-14 rounded-2xl flex-[2] text-lg font-bold shadow-lg h-14 bg-primary text-primary-foreground hover:opacity-90" onClick={() => setStep(3)}>Got it!</Button>
            </CardFooter>
        </Card>
      )}

      {step === 3 && (
        <Card className="border-none shadow-xl rounded-[2.5rem] p-4 animate-in fade-in slide-in-from-right-4 duration-500 text-center text-left bg-white">
            <CardHeader className="text-center text-left">
                <div className="w-24 h-24 bg-primary/10 rounded-full flex items-center justify-center mx-auto mb-6 text-primary-foreground">
                    <Sparkles className="w-12 h-12" />
                </div>
                <CardTitle className="text-3xl font-black text-center leading-tight">All set!</CardTitle>
                <CardDescription className="text-lg text-center text-muted-foreground">You&apos;re ready to start your journey on DataMint.</CardDescription>
            </CardHeader>
            <CardFooter className="pt-8 flex flex-col gap-4 text-left">
                <Button
                    className="w-full h-14 rounded-2xl text-lg font-bold shadow-lg flex items-center justify-center gap-2 group h-14 bg-primary text-primary-foreground hover:opacity-90"
                    onClick={handleCompleteOnboarding}
                    disabled={saving}
                >
                    {saving ? 'Saving...' : (
                        <>
                            Go to {role === 'creator' ? 'Dashboard' : 'Tasks'}
                            <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                        </>
                    )}
                </Button>
            </CardFooter>
        </Card>
      )}
    </div>
  )
}
