'use client'

import { useState, useEffect, useCallback, use } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { ethers, type Eip1193Provider } from 'ethers'
import { CheckCircle2, XCircle, Clock, Coins } from 'lucide-react'

const ESCROW_ABI = [
  "function approveWork(uint256 _datasetId, address _contributor) external"
]

interface WindowWithEthereum extends Window {
  ethereum?: Eip1193Provider
}

interface Submission {
  id: number
  user_id: string
  file_url: string | null
  content: string | null
  ai_score: number | null
  ai_feedback: string | null
  status: 'pending' | 'approved' | 'rejected'
  created_at: string
  users?: { wallet_address: string | null }
}

export default function SubmissionsPage({ params }: { params: Promise<{ datasetId: string }> }) {
  const { datasetId } = use(params)
  const [submissions, setSubmissions] = useState<Submission[]>([])
  const [dataset, setDataset] = useState<{ title: string; reward_per_task: number } | null>(null)
  const [loading, setLoading] = useState(true)
  const [payingId, setPayingId] = useState<number | null>(null)
  const supabase = createClient()

  const fetchSubmissions = useCallback(async () => {
    const [{ data: ds }, { data: subs }] = await Promise.all([
      supabase.from('datasets').select('title, reward_per_task').eq('id', datasetId).single(),
      supabase.from('submissions').select('*, users(wallet_address)').eq('dataset_id', datasetId).order('created_at', { ascending: false })
    ])
    if (ds) setDataset(ds)
    if (subs) setSubmissions(subs as Submission[])
    setLoading(false)
  }, [supabase, datasetId])

  useEffect(() => {
    if (datasetId) {
      fetchSubmissions()
    }
  }, [fetchSubmissions, datasetId])

  const handleApprovePay = async (submission: Submission) => {
    setPayingId(submission.id)
    try {
      const win = window as unknown as WindowWithEthereum
      if (!win.ethereum) throw new Error('Wallet not found')

      const provider = new ethers.BrowserProvider(win.ethereum)
      const signer = await provider.getSigner()
      const escrowAddress = process.env.NEXT_PUBLIC_ESCROW_CONTRACT_ADDRESS || ''
      const escrow = new ethers.Contract(escrowAddress, ESCROW_ABI, signer)

      const contributorWallet = submission.users?.wallet_address
      if (!contributorWallet) throw new Error('Contributor has no wallet address on file')

      const tx = await escrow.approveWork(Number(datasetId), contributorWallet)
      const receipt = await tx.wait()

      await supabase.from('payments').insert({
        submission_id: submission.id,
        dataset_id: Number(datasetId),
        wallet_address: contributorWallet,
        amount: dataset?.reward_per_task || 0,
        tx_hash: receipt.hash
      })

      await supabase.from('submissions').update({ status: 'approved' }).eq('id', submission.id)

      fetchSubmissions()
      alert(`Paid! Tx: ${receipt.hash}`)
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err)
      alert('Payment failed: ' + msg)
    } finally {
      setPayingId(null)
    }
  }

  if (loading) return <div className="flex items-center justify-center py-20"><div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" /></div>

  return (
    <div className="max-w-4xl mx-auto px-4 py-8 space-y-8">
      <div>
        <h1 className="text-3xl font-black">{dataset?.title}</h1>
        <p className="text-muted-foreground">Reward per task: {dataset?.reward_per_task} cUSD</p>
      </div>

      <div className="flex gap-4 text-sm font-bold">
        <span className="text-green-600">{submissions.filter(s => s.status === 'approved').length} Approved</span>
        <span className="text-amber-600">{submissions.filter(s => s.status === 'pending').length} Pending</span>
        <span className="text-red-500">{submissions.filter(s => s.status === 'rejected').length} Rejected</span>
      </div>

      {submissions.length === 0 ? (
        <p className="text-muted-foreground">No submissions yet.</p>
      ) : (
        <div className="space-y-4">
          {submissions.map((sub) => (
            <Card key={sub.id} className="border-none shadow-lg rounded-3xl">
              <CardHeader className="pb-2">
                <div className="flex justify-between items-center">
                  <CardTitle className="text-base font-bold">Submission #{sub.id}</CardTitle>
                  <Badge className={
                    sub.status === 'approved' ? 'bg-green-100 text-green-700 border-none' :
                    sub.status === 'rejected' ? 'bg-red-100 text-red-600 border-none' :
                    'bg-amber-100 text-amber-700 border-none'
                  }>
                    {sub.status === 'approved' && <CheckCircle2 className="w-3 h-3 mr-1" />}
                    {sub.status === 'rejected' && <XCircle className="w-3 h-3 mr-1" />}
                    {sub.status === 'pending' && <Clock className="w-3 h-3 mr-1" />}
                    {sub.status.toUpperCase()}
                  </Badge>
                </div>
                <CardDescription className="text-xs">
                  {new Date(sub.created_at).toLocaleString()} · AI Score: {sub.ai_score !== null ? `${sub.ai_score}/100` : 'Pending'}
                </CardDescription>
              </CardHeader>
              <CardContent className="pb-2 text-sm text-muted-foreground">
                {sub.content && <p className="line-clamp-2">{sub.content}</p>}
                {sub.file_url && <p className="italic">File: {sub.file_url.split('/').pop()}</p>}
                {sub.ai_feedback && <p className="text-xs mt-2 italic text-primary-foreground/60">AI: {sub.ai_feedback}</p>}
              </CardContent>
              {sub.status === 'pending' && (
                <CardFooter>
                  <Button
                    onClick={() => handleApprovePay(sub)}
                    disabled={payingId === sub.id}
                    className="rounded-2xl font-bold bg-primary text-primary-foreground hover:opacity-90"
                  >
                    <Coins className="w-4 h-4 mr-2" />
                    {payingId === sub.id ? 'Sending payment...' : 'Approve & Pay on Chain'}
                  </Button>
                </CardFooter>
              )}
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
