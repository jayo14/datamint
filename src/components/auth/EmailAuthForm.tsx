'use client'

import React, { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { UserRole } from './RoleSelector'

interface EmailAuthFormProps {
  role: UserRole
  onSuccess: (email: string) => void
  onError: (errorMsg: string) => void
}

export function EmailAuthForm({ role, onSuccess, onError }: EmailAuthFormProps) {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const supabase = createClient()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email || !email.includes('@')) {
      onError('Please enter a valid email address.')
      return
    }

    setLoading(true)
    try {
      document.cookie = `datamint_intended_role=${role}; path=/; max-age=3600`

      const { error } = await supabase.auth.signInWithOtp({
        email,
        options: {
          emailRedirectTo: `${window.location.origin}/auth/callback`,
        },
      })

      if (error) {
        throw error
      }

      onSuccess(email)
    } catch (err: unknown) {
      console.error('Email login error:', err)
      const message = err instanceof Error ? err.message : String(err)
      onError(message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      {/* Visual Divider */}
      <div className="relative my-6">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-[#BFE3D2]/70" />
        </div>
        <div className="relative flex justify-center text-xs uppercase tracking-wider">
          <span className="bg-white px-4 text-[#3F5F52] font-semibold">
            Or continue with email
          </span>
        </div>
      </div>

      <form onSubmit={handleLogin} className="space-y-3.5">
        <div className="space-y-1.5">
          <label
            htmlFor="email-input"
            className="text-xs font-bold uppercase tracking-wider text-[#3F5F52] block"
          >
            Email Address
          </label>
          <div className="relative">
            <span
              className="ms text-xl text-[#3F5F52] absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none"
              aria-hidden="true"
            >
              mail
            </span>
            <input
              id="email-input"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="name@example.com"
              required
              disabled={loading}
              className="w-full h-14 pl-12 pr-4 rounded-2xl bg-[#EAFBF3]/50 border border-[#BFE3D2] text-[#0D1F18] placeholder:text-[#3F5F52]/60 focus:bg-white focus:outline-none focus:border-[#74E3B6] focus:ring-4 focus:ring-[#74E3B6]/20 transition-all font-medium text-base"
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={loading}
          className="btn w-full !h-14 !rounded-full !flex !items-center !justify-center !gap-2 text-[#0D1F18] font-bold text-base cursor-pointer shadow-[0_10px_25px_-5px_rgba(116,227,182,0.4)] disabled:opacity-60"
          data-element-type="button"
          data-label="Send Magic Link"
        >
          {loading ? (
            <span className="flex items-center gap-2">
              <span className="w-5 h-5 border-2 border-[#0D1F18] border-t-transparent rounded-full animate-spin" />
              <span>Sending secure link...</span>
            </span>
          ) : (
            <span className="flex items-center gap-2">
              <span>Send Magic Link</span>
              <span className="ms text-xl" aria-hidden="true">arrow_forward</span>
            </span>
          )}
        </button>
      </form>
    </div>
  )
}
