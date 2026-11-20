'use client'

import React, { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useWeb3 } from '@/hooks/useWeb3'
import type { UserRole } from './RoleSelector'

interface EthereumProvider {
  request: (args: { method: string; params?: unknown[] }) => Promise<string[]>
}

interface WindowWithEthereum extends Window {
  ethereum?: EthereumProvider
}

interface WalletAuthButtonProps {
  role: UserRole
  onSuccess: (message: string, address: string) => void
  onError: (errorMsg: string) => void
}

export function WalletAuthButton({ role, onSuccess, onError }: WalletAuthButtonProps) {
  const [loading, setLoading] = useState(false)
  const supabase = createClient()
  const { address, isConnected } = useWeb3()

  const handleWalletConnect = async () => {
    const win = typeof window !== 'undefined' ? (window as unknown as WindowWithEthereum) : null

    if (!win?.ethereum) {
      onError('No Web3 wallet detected. Please install MiniPay or MetaMask to continue.')
      return
    }

    setLoading(true)
    try {
      const accounts = await win.ethereum.request({ method: 'eth_requestAccounts' })
      const walletAddress = accounts[0]

      if (!walletAddress) {
        throw new Error('No account returned by wallet')
      }

      // Persist intended role and wallet address cookies
      document.cookie = `datamint_intended_role=${role}; path=/; max-age=3600`
      document.cookie = `datamint_wallet_address=${walletAddress}; path=/; max-age=3600`

      const emailForWallet = `${walletAddress.toLowerCase()}@datamint.io`

      const { error } = await supabase.auth.signInWithOtp({
        email: emailForWallet,
        options: {
          emailRedirectTo: `${window.location.origin}/auth/callback`,
        },
      })

      if (error) throw error

      onSuccess(
        'Wallet linked successfully! A secure verification token has been generated for your Web3 address.',
        walletAddress
      )
    } catch (err: unknown) {
      console.error('Wallet authentication error:', err)
      const message = err instanceof Error ? err.message : String(err)
      onError(`Wallet connection failed: ${message}`)
    } finally {
      setLoading(false)
    }
  }

  const truncate = (addr: string) => `${addr.slice(0, 6)}...${addr.slice(-4)}`

  return (
    <div className="space-y-2">
      <button
        type="button"
        onClick={handleWalletConnect}
        disabled={loading}
        className="w-full h-14 rounded-full border-1.5 border-[#BFE3D2] bg-white hover:bg-[#EAFBF3]/60 text-[#0D1F18] font-semibold text-base transition-all duration-200 flex items-center justify-center gap-3 shadow-sm hover:shadow active:scale-[0.99] disabled:opacity-60 cursor-pointer"
        data-element-type="button"
        data-label="Connect Web3 Wallet"
      >
        <span className="w-8 h-8 rounded-full bg-[#74E3B6]/30 flex items-center justify-center text-[#0D1F18] flex-none">
          <span className="ms text-xl" aria-hidden="true">account_balance_wallet</span>
        </span>

        {loading ? (
          <span className="flex items-center gap-2">
            <span className="w-4 h-4 border-2 border-[#0D1F18] border-t-transparent rounded-full animate-spin" />
            <span>Connecting Wallet...</span>
          </span>
        ) : isConnected && address ? (
          <span className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-[#0B9E6B]" />
            <span>Continue as {truncate(address)}</span>
          </span>
        ) : (
          <span>Continue with MiniPay / MetaMask</span>
        )}
      </button>

      <div className="flex items-center justify-center gap-3 text-xs text-[#3F5F52]">
        <span className="flex items-center gap-1">
          <span className="ms text-sm text-[#0B9E6B]" aria-hidden="true">check_circle</span>
          Gasless on MiniPay
        </span>
        <span>•</span>
        <span className="flex items-center gap-1">
          <span className="ms text-sm text-[#0B9E6B]" aria-hidden="true">verified_user</span>
          Instant Celo Payouts
        </span>
      </div>
    </div>
  )
}
