'use client'

import { useState, useEffect } from 'react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card'
import { registerAgent, getAgentId } from '@/lib/erc8004'
import { ethers, type Eip1193Provider } from 'ethers'
import { ShieldCheck, ExternalLink, Sparkles } from 'lucide-react'

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
      if (!win.ethereum) throw new Error('Wallet not found')

      const provider = new ethers.BrowserProvider(win.ethereum)
      const signer = await provider.getSigner()
      const metadataURI = "https://ogkpnvtlzsnflxzjzbus.supabase.co/storage/v1/object/public/submissions/datamint-agent.json"
      const receipt = await registerAgent(signer, "DataMint", metadataURI)
      const id = await getAgentId(signer)
      setAgentId(id)
      alert('Agent registered! ID: ' + id)
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : String(err))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto px-4 py-12 space-y-8">
      <Card className="border-none shadow-2xl rounded-[3rem] overflow-hidden bg-white">
        <CardHeader className="bg-primary/10 p-12 text-center border-b border-primary/20">
          <div className="w-20 h-20 bg-white rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-xl shadow-primary/10">
            <ShieldCheck className="w-10 h-10 text-primary-foreground" />
          </div>
          <CardTitle className="text-4xl font-black tracking-tight leading-none">ERC-8004 Agent Registration</CardTitle>
          <CardDescription className="text-lg pt-4 text-muted-foreground leading-relaxed">
            Register DataMint as an official AI Agent on the Celo network to qualify for Hackathon Track 3.
          </CardDescription>
        </CardHeader>
        <CardContent className="p-12 space-y-6">
          {agentId ? (
            <div className="bg-green-50 border border-green-200 p-8 rounded-[2rem] text-center space-y-4">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto">
                <Sparkles className="w-8 h-8 text-green-600" />
              </div>
              <h3 className="text-2xl font-bold text-green-800">Agent Registered!</h3>
              <p className="text-green-700 font-medium text-lg">Your Agent ID: <span className="font-black text-3xl block pt-2">#{agentId}</span></p>
              <Button asChild variant="outline" className="rounded-full border-green-200 hover:bg-green-100 mt-4">
                <a href="https://8004scan.io" target="_blank" rel="noopener noreferrer">
                  View on 8004scan.io <ExternalLink className="ml-2 w-4 h-4" />
                </a>
              </Button>
            </div>
          ) : (
            <div className="space-y-6">
              <p className="text-muted-foreground text-center text-lg leading-relaxed">
                By registering, you link your wallet to the DataMint Agent identity on-chain. This metadata describes DataMint's capabilities for dataset creation and human-in-the-loop validation.
              </p>
              {error && <p className="text-red-500 text-sm font-bold text-center">Error: {error}</p>}
            </div>
          )}
        </CardContent>
        {!agentId && (
          <CardFooter className="p-12 pt-0">
            <Button
              onClick={handleRegister}
              disabled={loading}
              className="w-full h-16 rounded-[2rem] text-xl font-bold shadow-xl shadow-primary/20 bg-primary text-primary-foreground hover:opacity-90"
            >
              {loading ? 'Registering Agent...' : 'Register Agent on Celo'}
            </Button>
          </CardFooter>
        )}
      </Card>
    </div>
  )
}
