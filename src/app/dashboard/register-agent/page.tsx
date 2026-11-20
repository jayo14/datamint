'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { registerAgent, getAgentId } from '@/lib/erc8004'
import { ethers, type Eip1193Provider } from 'ethers'

interface WindowWithEthereum extends Window {
  ethereum?: Eip1193Provider
}

export default function RegisterAgentPage() {
  const [loading, setLoading] = useState(false)
  const [agentId, setAgentId] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const checkAgent = async () => {
      const win = window as unknown as WindowWithEthereum
      if (win.ethereum) {
        try {
          const provider = new ethers.BrowserProvider(win.ethereum)
          const signer = await provider.getSigner()
          const id = await getAgentId(signer)
          if (id && id !== '0') setAgentId(id)
        } catch (e) {
          console.error(e)
        }
      }
    }
    checkAgent()
  }, [])

  const handleRegister = async () => {
    setLoading(true)
    setError(null)
    try {
      const win = window as unknown as WindowWithEthereum
      if (!win.ethereum) throw new Error('Web3 wallet not detected. Please install MiniPay or MetaMask.')

      const provider = new ethers.BrowserProvider(win.ethereum)
      const signer = await provider.getSigner()
      const metadataURI =
        'https://ogkpnvtlzsnflxzjzbus.supabase.co/storage/v1/object/public/submissions/datamint-agent.json'
      await registerAgent(signer, 'DataMint', metadataURI)
      const id = await getAgentId(signer)
      setAgentId(id)
      alert('AI Agent successfully registered on Celo! Agent ID: ' + id)
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6 pb-16">
      {/* Back button */}
      <div>
        <Link
          href="/dashboard"
          className="inline-flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-[#3F5F52] hover:text-[#0D1F18] transition-colors"
        >
          <span className="material-symbols-rounded text-base">arrow_back</span>
          Back to Dashboard
        </Link>
      </div>

      <Card className="rounded-[36px] sm:rounded-[44px] border border-[#BFE3D2] bg-white p-6 sm:p-12 shadow-sm">
        <CardHeader className="text-center p-0 pb-8">
          <div className="w-20 h-20 rounded-[26px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center mx-auto mb-5 text-[#0D1F18] shadow-xs">
            <span className="material-symbols-rounded text-4xl text-[#0B9E6B]">smart_toy</span>
          </div>

          <div className="inline-flex items-center justify-center gap-2 px-3.5 py-1.5 rounded-full bg-[#EAFBF3] border border-[#BFE3D2] mx-auto mb-3">
            <span className="w-2 h-2 rounded-full bg-[#0B9E6B] animate-pulse" />
            <span className="text-xs font-bold uppercase tracking-wider text-[#3F5F52]">
              Celo Hackathon Track 3
            </span>
          </div>

          <CardTitle className="font-bricolage text-3xl sm:text-4xl font-bold tracking-tight text-[#0D1F18]">
            ERC-8004 Agent Registration
          </CardTitle>
          <CardDescription className="text-sm sm:text-base text-[#3F5F52] max-w-md mx-auto mt-2 leading-relaxed">
            Register DataMint as an autonomous AI Agent on the Celo network to enable on-chain verification and decentralized dataset governance.
          </CardDescription>
        </CardHeader>

        <CardContent className="p-0 space-y-6">
          {agentId ? (
            <div className="rounded-[28px] bg-gradient-to-b from-[#EAFBF3] to-white border border-[#BFE3D2] p-8 text-center space-y-4 shadow-xs">
              <div className="w-14 h-14 rounded-full bg-[#74E3B6] flex items-center justify-center mx-auto text-[#0D1F18]">
                <span className="material-symbols-rounded text-3xl">verified</span>
              </div>
              <div>
                <Badge variant="success" size="sm" className="mb-2">
                  Active On-Chain Identity
                </Badge>
                <h3 className="font-bricolage text-2xl font-bold text-[#0D1F18]">
                  Agent Registered Successfully
                </h3>
                <p className="text-xs text-[#3F5F52] mt-1">
                  Your Celo wallet is linked to the DataMint autonomous agent profile.
                </p>
              </div>

              <div className="rounded-[20px] bg-white border border-[#BFE3D2] py-4 px-6 inline-block">
                <span className="text-xs font-semibold text-[#3F5F52] block uppercase tracking-wider">
                  Official Agent ID
                </span>
                <span className="font-bricolage text-3xl sm:text-4xl font-black text-[#0D1F18]">
                  #{agentId}
                </span>
              </div>

              <div>
                <a
                  href="https://8004scan.io"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-block"
                >
                  <Button variant="outline" className="rounded-full shadow-xs">
                    <span>View on 8004scan.io</span>
                    <span className="material-symbols-rounded text-base">open_in_new</span>
                  </Button>
                </a>
              </div>
            </div>
          ) : (
            <div className="space-y-6">
              {/* Feature Highlights */}
              <div className="space-y-3">
                <div className="rounded-[22px] bg-[#EAFBF3]/60 border border-[#BFE3D2]/70 p-4 flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-full bg-white border border-[#BFE3D2] flex items-center justify-center text-[#0B9E6B] shrink-0">
                    <span className="material-symbols-rounded text-xl">bolt</span>
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-[#0D1F18]">Autonomous Escrow Triggers</h4>
                    <p className="text-xs text-[#3F5F52] mt-0.5 leading-relaxed">
                      AI agents can evaluate contributor submissions against accuracy benchmarks and initiate instant payouts.
                    </p>
                  </div>
                </div>

                <div className="rounded-[22px] bg-[#EAFBF3]/60 border border-[#BFE3D2]/70 p-4 flex items-start gap-3.5">
                  <div className="w-9 h-9 rounded-full bg-white border border-[#BFE3D2] flex items-center justify-center text-[#0B9E6B] shrink-0">
                    <span className="material-symbols-rounded text-xl">verified_user</span>
                  </div>
                  <div>
                    <h4 className="text-sm font-bold text-[#0D1F18]">On-Chain Agent Identity</h4>
                    <p className="text-xs text-[#3F5F52] mt-0.5 leading-relaxed">
                      Links the DataMint dataset pipeline metadata URI with your cryptographic address on Celo.
                    </p>
                  </div>
                </div>
              </div>

              {error && (
                <div className="p-4 rounded-[18px] bg-red-50 border border-red-200 text-xs text-red-700 font-medium">
                  {error}
                </div>
              )}
            </div>
          )}
        </CardContent>

        {!agentId && (
          <CardFooter className="p-0 pt-8 mt-6 border-t border-[#BFE3D2]/40">
            <Button
              onClick={handleRegister}
              disabled={loading}
              className="w-full h-14 rounded-full font-bricolage text-lg font-bold shadow-md"
            >
              <span className="material-symbols-rounded text-xl">how_to_reg</span>
              {loading ? 'Registering Agent on Celo...' : 'Register Agent on Celo'}
            </Button>
          </CardFooter>
        )}
      </Card>
    </div>
  )
}
