'use client'

import React, { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { AuthNavbar } from '@/components/auth/AuthNavbar'
import { useWeb3 } from '@/hooks/useWeb3'

interface UserProfile {
  id: string
  role: 'creator' | 'contributor' | null
  wallet_address?: string
}

export default function Onboarding() {
  const [step, setStep] = useState(1)
  const [role, setRole] = useState<'creator' | 'contributor' | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [user, setUser] = useState<{ id: string; email?: string } | null>(null)
  const router = useRouter()
  const supabase = createClient()
  const { address } = useWeb3()

  useEffect(() => {
    const checkUser = async () => {
      const {
        data: { user: authUser },
      } = await supabase.auth.getUser()

      if (!authUser) {
        router.push('/login')
        return
      }

      setUser({ id: authUser.id, email: authUser.email })

      // Check cookie for intended role
      const cookieRole = document.cookie
        .split('; ')
        .find((row) => row.startsWith('datamint_intended_role='))
        ?.split('=')[1] as 'creator' | 'contributor' | undefined

      const { data: profile } = (await supabase
        .from('users')
        .select('role')
        .eq('id', authUser.id)
        .single()) as { data: UserProfile | null }

      if (profile?.role) {
        setRole(profile.role)
      } else if (cookieRole === 'creator' || cookieRole === 'contributor') {
        setRole(cookieRole)
      }

      setLoading(false)
    }

    checkUser()
  }, [router, supabase])

  const handleCompleteOnboarding = async () => {
    if (!role || !user) return
    setSaving(true)

    // Get wallet address from cookie or web3 provider
    const walletCookie = document.cookie
      .split('; ')
      .find((row) => row.startsWith('datamint_wallet_address='))
    const walletAddress = walletCookie ? walletCookie.split('=')[1] : address || null

    const { error } = await supabase.from('users').upsert({
      id: user.id,
      role: role,
      wallet_address: walletAddress,
    })

    if (error) {
      alert(error.message)
      setSaving(false)
    } else {
      router.push(role === 'creator' ? '/dashboard' : '/tasks')
    }
  }

  if (loading) {
    return (
      <div className="pg min-h-screen flex flex-col items-center justify-center">
        <div className="w-14 h-14 rounded-full border-4 border-[#74E3B6] border-t-transparent animate-spin mb-4" />
        <p className="text-[#3F5F52] font-semibold text-sm">Preparing your session...</p>
      </div>
    )
  }

  return (
    <div className="pg min-h-screen flex flex-col justify-between selection:bg-[#74E3B6] selection:text-[#0D1F18]">
      <AuthNavbar showBackHome={false} currentStepBadge={`Step ${step} of 3 • Profile Setup`} />

      <main className="w-full flex-1 flex flex-col justify-center items-center px-4 py-8 md:py-12 relative overflow-hidden">
        {/* Ambient Decorative Glowing Coins */}
        <div
          className="coin w-36 h-36 -top-10 -left-10 md:left-14 pointer-events-none opacity-40 bg-[#74E3B6]"
          aria-hidden="true"
        />
        <div
          className="coin w-44 h-44 -bottom-10 -right-10 md:right-20 pointer-events-none opacity-30 bg-[#FFE08A]"
          style={{ animationDelay: '-4s' }}
          aria-hidden="true"
        />

        <div className="w-full max-w-[640px] z-10 mx-auto">
          {/* Step Progress Pill */}
          <div className="flex items-center justify-center gap-2.5 mb-8">
            {[1, 2, 3].map((s) => (
              <div
                key={s}
                className={`h-2.5 rounded-full transition-all duration-300 ${
                  step === s
                    ? 'w-16 bg-[#0B9E6B]'
                    : step > s
                    ? 'w-10 bg-[#74E3B6]'
                    : 'w-8 bg-[#BFE3D2]/60'
                }`}
              />
            ))}
          </div>

          {/* Step 1: Choose Role */}
          {step === 1 && (
            <div className="bg-white/95 backdrop-blur-xl border border-[#BFE3D2]/70 rounded-[36px] md:rounded-[44px] p-6 sm:p-10 shadow-[0_24px_50px_-15px_rgba(15,42,33,0.12)] space-y-8 animate-in fade-in slide-in-from-right-4 duration-300">
              <div className="text-center space-y-2">
                <div className="w-14 h-14 rounded-2xl bg-[#74E3B6]/30 flex items-center justify-center mx-auto text-[#0D1F18] mb-2">
                  <span className="ms text-2xl" aria-hidden="true">
                    diversity_3
                  </span>
                </div>
                <h2 className="h2 !text-2xl md:!text-3xl !font-medium text-[#0D1F18]">
                  Select your primary path
                </h2>
                <p className="text-[#3F5F52] text-sm md:text-base">
                  Choose how you want to interact with the DataMint protocol. You can switch roles at any time.
                </p>
              </div>

              <div className="grid grid-cols-1 gap-4">
                {/* Contributor Card */}
                <button
                  type="button"
                  onClick={() => setRole('contributor')}
                  className={`p-6 rounded-3xl border-2 text-left transition-all duration-200 cursor-pointer flex flex-col sm:flex-row items-start gap-4 ${
                    role === 'contributor'
                      ? 'border-[#0B9E6B] bg-[#EAFBF3] shadow-[0_12px_28px_-10px_rgba(11,158,107,0.25)]'
                      : 'border-[#BFE3D2]/70 hover:border-[#74E3B6] hover:bg-[#EAFBF3]/40'
                  }`}
                >
                  <div
                    className={`w-12 h-12 rounded-2xl flex items-center justify-center flex-none transition-colors ${
                      role === 'contributor'
                        ? 'bg-[#0B9E6B] text-white'
                        : 'bg-white border border-[#BFE3D2] text-[#3F5F52]'
                    }`}
                  >
                    <span className="ms text-2xl" aria-hidden="true">
                      paid
                    </span>
                  </div>

                  <div className="flex-1 space-y-1">
                    <div className="flex items-center justify-between">
                      <h3 className="font-bold text-lg text-[#0D1F18]">I am a Contributor</h3>
                      {role === 'contributor' && (
                        <span className="ms text-xl text-[#0B9E6B]" aria-hidden="true">
                          check_circle
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-[#3F5F52] leading-relaxed">
                      Complete micro-tasks like recording speech, taking photos, and labeling text.
                    </p>
                    <div className="pt-2 flex flex-wrap gap-2 text-[11px] font-semibold text-[#0B9E6B]">
                      <span className="px-2 py-0.5 rounded-full bg-white border border-[#BFE3D2]">Instant Celo cUSD</span>
                      <span className="px-2 py-0.5 rounded-full bg-white border border-[#BFE3D2]">MiniPay Friendly</span>
                    </div>
                  </div>
                </button>

                {/* Creator Card */}
                <button
                  type="button"
                  onClick={() => setRole('creator')}
                  className={`p-6 rounded-3xl border-2 text-left transition-all duration-200 cursor-pointer flex flex-col sm:flex-row items-start gap-4 ${
                    role === 'creator'
                      ? 'border-[#0B9E6B] bg-[#EAFBF3] shadow-[0_12px_28px_-10px_rgba(11,158,107,0.25)]'
                      : 'border-[#BFE3D2]/70 hover:border-[#74E3B6] hover:bg-[#EAFBF3]/40'
                  }`}
                >
                  <div
                    className={`w-12 h-12 rounded-2xl flex items-center justify-center flex-none transition-colors ${
                      role === 'creator'
                        ? 'bg-[#0B9E6B] text-white'
                        : 'bg-white border border-[#BFE3D2] text-[#3F5F52]'
                    }`}
                  >
                    <span className="ms text-2xl" aria-hidden="true">
                      psychology
                    </span>
                  </div>

                  <div className="flex-1 space-y-1">
                    <div className="flex items-center justify-between">
                      <h3 className="font-bold text-lg text-[#0D1F18]">I am an AI Creator / Team</h3>
                      {role === 'creator' && (
                        <span className="ms text-xl text-[#0B9E6B]" aria-hidden="true">
                          check_circle
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-[#3F5F52] leading-relaxed">
                      Request bespoke training data, fund audited escrow pools, and export verified datasets.
                    </p>
                    <div className="pt-2 flex flex-wrap gap-2 text-[11px] font-semibold text-[#0B9E6B]">
                      <span className="px-2 py-0.5 rounded-full bg-white border border-[#BFE3D2]">Smart Escrow</span>
                      <span className="px-2 py-0.5 rounded-full bg-white border border-[#BFE3D2]">Automated AI QA</span>
                    </div>
                  </div>
                </button>
              </div>

              <button
                type="button"
                disabled={!role}
                onClick={() => setStep(2)}
                className="btn w-full !h-14 !rounded-full !flex !items-center !justify-center !gap-2 text-[#0D1F18] font-bold text-base cursor-pointer shadow-[0_10px_25px_-5px_rgba(116,227,182,0.4)] disabled:opacity-50"
              >
                <span>Continue</span>
                <span className="ms text-xl" aria-hidden="true">
                  arrow_forward
                </span>
              </button>
            </div>
          )}

          {/* Step 2: Protocol Tour */}
          {step === 2 && (
            <div className="bg-white/95 backdrop-blur-xl border border-[#BFE3D2]/70 rounded-[36px] md:rounded-[44px] p-6 sm:p-10 shadow-[0_24px_50px_-15px_rgba(15,42,33,0.12)] space-y-8 animate-in fade-in slide-in-from-right-4 duration-300">
              <div className="text-center space-y-2">
                <div className="w-14 h-14 rounded-2xl bg-[#74E3B6]/30 flex items-center justify-center mx-auto text-[#0D1F18] mb-2">
                  <span className="ms text-2xl" aria-hidden="true">
                    route
                  </span>
                </div>
                <h2 className="h2 !text-2xl md:!text-3xl !font-medium text-[#0D1F18]">
                  How DataMint works for you
                </h2>
                <p className="text-[#3F5F52] text-sm md:text-base">
                  {role === 'creator'
                    ? '3 simple steps to collect production-grade datasets at scale.'
                    : '3 steps to turn your voice and observations into instant crypto earnings.'}
                </p>
              </div>

              {/* 3 Step Visual Cards */}
              <div className="space-y-3.5">
                {role === 'creator' ? (
                  <>
                    <div className="p-4 rounded-2xl bg-[#EAFBF3]/60 border border-[#BFE3D2] flex items-start gap-3.5">
                      <div className="w-8 h-8 rounded-full bg-[#0B9E6B] text-white flex-none flex items-center justify-center font-bold text-sm">
                        1
                      </div>
                      <div>
                        <h4 className="font-bold text-sm text-[#0D1F18]">Define & Scope Campaign</h4>
                        <p className="text-xs text-[#3F5F52] mt-0.5 leading-relaxed">
                          Choose task categories (Speech audio, OCR image, text prompts) and acceptance criteria.
                        </p>
                      </div>
                    </div>

                    <div className="p-4 rounded-2xl bg-[#EAFBF3]/60 border border-[#BFE3D2] flex items-start gap-3.5">
                      <div className="w-8 h-8 rounded-full bg-[#0B9E6B] text-white flex-none flex items-center justify-center font-bold text-sm">
                        2
                      </div>
                      <div>
                        <h4 className="font-bold text-sm text-[#0D1F18]">Lock Funds in Escrow</h4>
                        <p className="text-xs text-[#3F5F52] mt-0.5 leading-relaxed">
                          Deposit cUSD/CELO into our open-source, non-custodial smart escrow contract.
                        </p>
                      </div>
                    </div>

                    <div className="p-4 rounded-2xl bg-[#EAFBF3]/60 border border-[#BFE3D2] flex items-start gap-3.5">
                      <div className="w-8 h-8 rounded-full bg-[#0B9E6B] text-white flex-none flex items-center justify-center font-bold text-sm">
                        3
                      </div>
                      <div>
                        <h4 className="font-bold text-sm text-[#0D1F18]">AI Quality Gate & Export</h4>
                        <p className="text-xs text-[#3F5F52] mt-0.5 leading-relaxed">
                          Submissions pass multi-stage AI validation; export verified data anytime in JSONL.
                        </p>
                      </div>
                    </div>
                  </>
                ) : (
                  <>
                    <div className="p-4 rounded-2xl bg-[#EAFBF3]/60 border border-[#BFE3D2] flex items-start gap-3.5">
                      <div className="w-8 h-8 rounded-full bg-[#0B9E6B] text-white flex-none flex items-center justify-center font-bold text-sm">
                        1
                      </div>
                      <div>
                        <h4 className="font-bold text-sm text-[#0D1F18]">Discover Real-World Tasks</h4>
                        <p className="text-xs text-[#3F5F52] mt-0.5 leading-relaxed">
                          Browse regional African and global language prompts, photos, and micro-surveys.
                        </p>
                      </div>
                    </div>

                    <div className="p-4 rounded-2xl bg-[#EAFBF3]/60 border border-[#BFE3D2] flex items-start gap-3.5">
                      <div className="w-8 h-8 rounded-full bg-[#0B9E6B] text-white flex-none flex items-center justify-center font-bold text-sm">
                        2
                      </div>
                      <div>
                        <h4 className="font-bold text-sm text-[#0D1F18]">Record & Submit Clean Samples</h4>
                        <p className="text-xs text-[#3F5F52] mt-0.5 leading-relaxed">
                          Record clean audio or upload photos directly through your phone browser or MiniPay.
                        </p>
                      </div>
                    </div>

                    <div className="p-4 rounded-2xl bg-[#EAFBF3]/60 border border-[#BFE3D2] flex items-start gap-3.5">
                      <div className="w-8 h-8 rounded-full bg-[#0B9E6B] text-white flex-none flex items-center justify-center font-bold text-sm">
                        3
                      </div>
                      <div>
                        <h4 className="font-bold text-sm text-[#0D1F18]">Instant Escrow Release</h4>
                        <p className="text-xs text-[#3F5F52] mt-0.5 leading-relaxed">
                          Once validated by AI QA, funds are unlocked directly into your Celo wallet.
                        </p>
                      </div>
                    </div>
                  </>
                )}
              </div>

              <div className="flex items-center gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setStep(1)}
                  className="btn w2 !h-14 !px-6 text-sm font-semibold text-[#0D1F18] flex items-center justify-center gap-1.5 cursor-pointer"
                >
                  <span className="ms text-lg" aria-hidden="true">
                    arrow_back
                  </span>
                  <span>Back</span>
                </button>

                <button
                  type="button"
                  onClick={() => setStep(3)}
                  className="btn flex-1 !h-14 !rounded-full !flex !items-center !justify-center !gap-2 text-[#0D1F18] font-bold text-base cursor-pointer shadow-[0_10px_25px_-5px_rgba(116,227,182,0.4)]"
                >
                  <span>Ready to Launch</span>
                  <span className="ms text-xl" aria-hidden="true">
                    arrow_forward
                  </span>
                </button>
              </div>
            </div>
          )}

          {/* Step 3: Confirmation & Enter Platform */}
          {step === 3 && (
            <div className="bg-white/95 backdrop-blur-xl border border-[#BFE3D2]/70 rounded-[36px] md:rounded-[44px] p-6 sm:p-10 shadow-[0_24px_50px_-15px_rgba(15,42,33,0.12)] space-y-8 animate-in fade-in slide-in-from-right-4 duration-300 text-center">
              <div className="space-y-3">
                <div className="w-20 h-20 rounded-full bg-[#74E3B6]/30 flex items-center justify-center mx-auto text-[#0B9E6B]">
                  <span className="ms text-4xl" aria-hidden="true">
                    verified
                  </span>
                </div>
                <h2 className="h2 !text-3xl md:!text-4xl !font-medium text-[#0D1F18]">
                  You&apos;re all set!
                </h2>
                <p className="text-[#3F5F52] text-sm md:text-base max-w-sm mx-auto">
                  Your profile has been created as{' '}
                  <span className="font-bold text-[#0D1F18] capitalize">{role}</span>.
                </p>
              </div>

              <div className="p-4 rounded-2xl bg-[#EAFBF3] border border-[#BFE3D2] text-left text-xs text-[#3F5F52] space-y-2">
                <div className="flex justify-between items-center">
                  <span className="font-medium text-[#3F5F52]">Active Identity:</span>
                  <span className="font-bold text-[#0D1F18]">{user?.email || 'Web3 Account'}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="font-medium text-[#3F5F52]">Selected Mode:</span>
                  <span className="font-bold text-[#0B9E6B] uppercase tracking-wider">{role}</span>
                </div>
                {address && (
                  <div className="flex justify-between items-center">
                    <span className="font-medium text-[#3F5F52]">Linked Wallet:</span>
                    <span className="font-mono text-[#0D1F18]">
                      {address.slice(0, 8)}...{address.slice(-6)}
                    </span>
                  </div>
                )}
              </div>

              <div className="space-y-3 pt-2">
                <button
                  type="button"
                  disabled={saving}
                  onClick={handleCompleteOnboarding}
                  className="btn w-full !h-14 !rounded-full !flex !items-center !justify-center !gap-2 text-[#0D1F18] font-bold text-base cursor-pointer shadow-[0_10px_25px_-5px_rgba(116,227,182,0.4)] disabled:opacity-50"
                  data-element-type="button"
                  data-label="Enter Application"
                >
                  {saving ? (
                    <span className="flex items-center gap-2">
                      <span className="w-5 h-5 border-2 border-[#0D1F18] border-t-transparent rounded-full animate-spin" />
                      <span>Saving profile...</span>
                    </span>
                  ) : (
                    <span className="flex items-center gap-2">
                      <span>Enter {role === 'creator' ? 'Dataset Dashboard' : 'Tasks Marketplace'}</span>
                      <span className="ms text-xl" aria-hidden="true">
                        arrow_forward
                      </span>
                    </span>
                  )}
                </button>

                <button
                  type="button"
                  onClick={() => setStep(2)}
                  className="text-xs text-[#3F5F52] hover:text-[#0D1F18] font-medium underline"
                >
                  Review previous step
                </button>
              </div>
            </div>
          )}
        </div>
      </main>

      <footer className="py-6 text-center text-xs text-[#3F5F52] border-t border-[#BFE3D2]/40">
        <p>DataMint Protocol • Decentralized AI Data Escrow on Celo</p>
      </footer>
    </div>
  )
}
