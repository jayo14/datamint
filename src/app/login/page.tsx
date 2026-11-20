'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { AuthNavbar } from '@/components/auth/AuthNavbar'
import { AuthContainer } from '@/components/auth/AuthContainer'
import { RoleSelector, type UserRole } from '@/components/auth/RoleSelector'
import { WalletAuthButton } from '@/components/auth/WalletAuthButton'
import { EmailAuthForm } from '@/components/auth/EmailAuthForm'

export default function Login() {
  const [role, setRole] = useState<UserRole>('contributor')
  const [sentEmail, setSentEmail] = useState<string | null>(null)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [walletSuccessMessage, setWalletSuccessMessage] = useState<string | null>(null)

  const handleRoleChange = (newRole: UserRole) => {
    setRole(newRole)
    if (typeof document !== 'undefined') {
      document.cookie = `datamint_intended_role=${newRole}; path=/; max-age=3600`
    }
  }

  const handleEmailSuccess = (email: string) => {
    setErrorMessage(null)
    setWalletSuccessMessage(null)
    setSentEmail(email)
  }

  const handleWalletSuccess = (msg: string) => {
    setErrorMessage(null)
    setSentEmail(null)
    setWalletSuccessMessage(msg)
  }

  const handleError = (msg: string) => {
    setWalletSuccessMessage(null)
    setErrorMessage(msg)
  }

  return (
    <div className="min-h-screen flex flex-col bg-[#EAFBF3]">
      <AuthNavbar showBackHome={true} currentStepBadge="Auth Portal" />

      <AuthContainer
        badgeText="Decentralized Identity"
        badgeIcon="lock"
        title="Welcome to DataMint"
        subtitle="Sign in to contribute data, manage datasets, and claim instant escrow payouts on Celo."
        floatingTags={[
          {
            icon: 'shield_lock',
            text: 'Audited Smart Escrow',
            className: 'top-28 left-8 -rotate-6',
          },
          {
            icon: 'bolt',
            text: 'Sub-Second Payouts',
            className: 'top-40 right-10 rotate-6',
          },
          {
            icon: 'verified',
            text: 'AI Validation Pipeline',
            className: 'bottom-24 left-12 rotate-3',
          },
        ]}
      >
        <div className="space-y-6">
          {/* Error Banner */}
          {errorMessage && (
            <div className="p-4 rounded-2xl bg-red-50 border border-red-200 text-red-900 text-sm flex items-start gap-3 animate-in fade-in">
              <span className="ms text-red-600 text-xl flex-none" aria-hidden="true">
                error
              </span>
              <div className="flex-1">
                <p className="font-semibold">Authentication issue</p>
                <p className="text-xs text-red-700 mt-0.5">{errorMessage}</p>
              </div>
              <button
                type="button"
                onClick={() => setErrorMessage(null)}
                className="text-red-600 hover:text-red-900 text-xs font-bold"
              >
                ✕
              </button>
            </div>
          )}

          {/* Wallet Verification Notice */}
          {walletSuccessMessage && (
            <div className="p-4 rounded-2xl bg-[#EAFBF3] border border-[#BFE3D2] text-[#0D1F18] text-sm flex items-start gap-3 animate-in fade-in">
              <span className="ms text-[#0B9E6B] text-xl flex-none" aria-hidden="true">
                check_circle
              </span>
              <div className="flex-1">
                <p className="font-bold">Wallet Connected</p>
                <p className="text-xs text-[#3F5F52] mt-0.5">{walletSuccessMessage}</p>
              </div>
            </div>
          )}

          {/* Sent Email State */}
          {sentEmail ? (
            <div className="text-center py-6 space-y-4 animate-in fade-in slide-in-from-bottom-2">
              <div className="w-16 h-16 rounded-full bg-[#74E3B6]/30 mx-auto flex items-center justify-center text-[#0D1F18]">
                <span className="ms text-3xl text-[#0B9E6B]" aria-hidden="true">
                  mark_email_read
                </span>
              </div>
              <div className="space-y-1.5">
                <h3 className="text-xl font-bold text-[#0D1F18]">Check your inbox</h3>
                <p className="text-sm text-[#3F5F52]">
                  We sent a secure magic link to{' '}
                  <span className="font-bold text-[#0D1F18]">{sentEmail}</span>.
                </p>
              </div>
              <p className="text-xs text-[#3F5F52]/80 max-w-xs mx-auto">
                Click the link in the email to automatically sign in to your DataMint account.
              </p>

              <div className="pt-2">
                <button
                  type="button"
                  onClick={() => setSentEmail(null)}
                  className="text-xs font-semibold text-[#0B9E6B] hover:underline cursor-pointer"
                >
                  Use a different email address or method
                </button>
              </div>
            </div>
          ) : (
            <>
              {/* Role Selector */}
              <RoleSelector
                role={role}
                onRoleChange={handleRoleChange}
                showSubtitles={true}
              />

              {/* Web3 Wallet Option */}
              <div className="pt-1">
                <WalletAuthButton
                  role={role}
                  onSuccess={handleWalletSuccess}
                  onError={handleError}
                />
              </div>

              {/* Email Magic Link Option */}
              <EmailAuthForm
                role={role}
                onSuccess={handleEmailSuccess}
                onError={handleError}
              />
            </>
          )}

          {/* Terms and Privacy Footer */}
          <div className="pt-4 border-t border-[#BFE3D2]/50 text-center">
            <p className="text-xs text-[#3F5F52] leading-relaxed">
              By accessing DataMint, you agree to our{' '}
              <Link href="/#escrow" className="font-semibold text-[#0D1F18] underline hover:text-[#0B9E6B]">
                Escrow Terms
              </Link>{' '}
              and{' '}
              <Link href="/#how" className="font-semibold text-[#0D1F18] underline hover:text-[#0B9E6B]">
                Protocol Guidelines
              </Link>
              .
            </p>
          </div>
        </div>
      </AuthContainer>
    </div>
  )
}
