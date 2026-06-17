'use client'

import { useState, useEffect, useCallback, use } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { CheckCircle2, XCircle, Clock, Coins } from 'lucide-react'
import { useWeb3 } from '@/hooks/useWeb3'
import { releasePayment } from '@/lib/blockchain'

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
  const { signer } = useWeb3()

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
    let mounted = true;
    if (datasetId) {
      const load = async () => {
        const [{ data: ds }, { data: subs }] = await Promise.all([
          supabase.from('datasets').select('title, reward_per_task').eq('id', datasetId).single(),
          supabase.from('submissions').select('*, users(wallet_address)').eq('dataset_id', datasetId).order('created_at', { ascending: false })
        ])
        if (mounted) {
          if (ds) setDataset(ds)
          if (subs) setSubmissions(subs as Submission[])
          setLoading(false)
        }
      }
      void load()
    }
    return () => { mounted = false }
  }, [datasetId, supabase])

  const handleApprovePay = async (submission: Submission) => {
    if (!signer) {
        alert('Please connect your wallet first')
        return
    }
    setPayingId(submission.id)
    try {
      const contributorWallet = submission.users?.wallet_address
      if (!contributorWallet) throw new Error('Contributor has no wallet address on file')

      const txHash = await releasePayment(signer, Number(datasetId), contributorWallet)

      await supabase.from('payments').insert({
        submission_id: submission.id,
        dataset_id: Number(datasetId),
        wallet_address: contributorWallet,
        amount: dataset?.reward_per_task || 0,
        tx_hash: txHash
      })

      await supabase.from('submissions').update({ status: 'approved' }).eq('id', submission.id)

      void fetchSubmissions()
      alert(`Paid! Tx: ${txHash}`)
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err)
      alert('Payment failed: ' + message)
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
