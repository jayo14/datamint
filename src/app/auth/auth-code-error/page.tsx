'use client'

import React from 'react'
import Link from 'next/link'
import { AuthNavbar } from '@/components/auth/AuthNavbar'
import { AuthContainer } from '@/components/auth/AuthContainer'

export default function AuthCodeError() {
  return (
    <div className="min-h-screen flex flex-col bg-[#EAFBF3]">
      <AuthNavbar showBackHome={true} currentStepBadge="Authentication Error" />

      <AuthContainer
        badgeText="Verification Issue"
        badgeIcon="warning"
        title="Unable to Authenticate"
        subtitle="The sign-in link is either expired, already used, or invalid."
      >
        <div className="space-y-6 text-center">
          <div className="w-16 h-16 rounded-full bg-amber-100 border border-amber-200 mx-auto flex items-center justify-center text-amber-700">
            <span className="ms text-3xl" aria-hidden="true">
              link_off
            </span>
          </div>

          <div className="space-y-2">
            <h3 className="text-xl font-bold text-[#0D1F18]">
              Magic Link Expired or Invalid
            </h3>
            <p className="text-sm text-[#3F5F52] leading-relaxed max-w-sm mx-auto">
              For your account security, DataMint authentication links expire shortly after generation and can only be used once.
            </p>
          </div>

          {/* Troubleshooting Card */}
          <div className="p-4 rounded-2xl bg-[#EAFBF3] border border-[#BFE3D2] text-left space-y-2.5">
            <p className="text-xs font-bold uppercase tracking-wider text-[#0D1F18]">
              Common solutions
            </p>
            <ul className="text-xs text-[#3F5F52] space-y-2">
              <li className="flex items-start gap-2">
                <span className="ms text-base text-[#0B9E6B] flex-none">check_circle</span>
                <span>Open the link on the same browser device where you requested it.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="ms text-base text-[#0B9E6B] flex-none">check_circle</span>
                <span>Ensure third-party cookies and session storage are permitted.</span>
              </li>
              <li className="flex items-start gap-2">
                <span className="ms text-base text-[#0B9E6B] flex-none">check_circle</span>
                <span>If connecting with MiniPay or MetaMask, ensure your wallet is unlocked.</span>
              </li>
            </ul>
          </div>

          {/* Actions */}
          <div className="space-y-3 pt-2">
            <Link
              href="/login"
              className="btn w-full !h-14 !rounded-full !flex !items-center !justify-center !gap-2 text-[#0D1F18] font-bold text-base cursor-pointer shadow-[0_10px_25px_-5px_rgba(116,227,182,0.4)]"
            >
              <span>Request New Magic Link</span>
              <span className="ms text-xl" aria-hidden="true">
                refresh
              </span>
            </Link>

            <Link
              href="/"
              className="btn w2 w-full !h-12 !rounded-full !flex !items-center !justify-center !gap-2 text-sm font-semibold text-[#0D1F18]"
            >
              <span>Return to Homepage</span>
            </Link>
          </div>
        </div>
      </AuthContainer>
    </div>
  )
}
