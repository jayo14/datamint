'use client'

import { useState, useEffect, useCallback, use } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { api, type SubmissionDetails } from '@/lib/api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { useWeb3 } from '@/hooks/useWeb3'
import { releasePayment } from '@/lib/blockchain'

interface Submission {
  id: number | string
  user_id: string
  file_url: string | null
  content: string | null
  ai_score: number | null
  ai_feedback: string | null
  status: 'pending' | 'approved' | 'rejected' | string
  created_at: string
  users?: { wallet_address: string | null }
}

export default function SubmissionsPage({ params }: { params: Promise<{ datasetId: string }> }) {
  const { datasetId } = use(params)
  const [submissions, setSubmissions] = useState<Submission[]>([])
  const [dataset, setDataset] = useState<{ title: string; reward_per_task: number } | null>(null)
  const [loading, setLoading] = useState(true)
  const [payingId, setPayingId] = useState<number | string | null>(null)
  const supabase = createClient()
  const { signer } = useWeb3()

  const fetchSubmissions = useCallback(async () => {
    try {
      const [backendCampaign, backendSubs] = await Promise.all([
        api.getCampaign(datasetId),
        api.getCampaignSubmissions(datasetId),
      ])
      if (backendCampaign) {
        setDataset({
          title: backendCampaign.title,
          reward_per_task:
            typeof backendCampaign.reward_per_submission === 'string'
              ? parseFloat(backendCampaign.reward_per_submission)
              : backendCampaign.reward_per_submission,
        })
      }
      if (backendSubs && backendSubs.items) {
        const mappedSubs: Submission[] = backendSubs.items.map((s: SubmissionDetails) => {
          const latestRun = s.validation_runs?.[s.validation_runs.length - 1]
          return {
            id: s.id,
            user_id: s.contributor_id,
            file_url: s.assets?.[0]?.storage_key || null,
            content: s.content_payload ? JSON.stringify(s.content_payload) : null,
            ai_score: latestRun?.score ?? null,
            ai_feedback: latestRun?.findings?.map((f) => f.message).join('; ') || null,
            status: s.status.toLowerCase(),
            created_at: s.created_at,
          }
        })
        setSubmissions(mappedSubs)
        setLoading(false)
        return
      }
    } catch {
      // Fallback to supabase
    }

    const [{ data: ds }, { data: subs }] = await Promise.all([
      supabase.from('datasets').select('title, reward_per_task').eq('id', datasetId).single(),
      supabase
        .from('submissions')
        .select('*, users(wallet_address)')
        .eq('dataset_id', datasetId)
        .order('created_at', { ascending: false }),
    ])
    if (ds) setDataset(ds)
    if (subs) setSubmissions(subs as Submission[])
    setLoading(false)
  }, [supabase, datasetId])

  useEffect(() => {
    let mounted = true
    if (datasetId) {
      const load = async () => {
        try {
          const [backendCampaign, backendSubs] = await Promise.all([
            api.getCampaign(datasetId),
            api.getCampaignSubmissions(datasetId),
          ])
          if (backendCampaign && mounted) {
            setDataset({
              title: backendCampaign.title,
              reward_per_task:
                typeof backendCampaign.reward_per_submission === 'string'
                  ? parseFloat(backendCampaign.reward_per_submission)
                  : backendCampaign.reward_per_submission,
            })
          }
          if (backendSubs && backendSubs.items && mounted) {
            const mappedSubs: Submission[] = backendSubs.items.map((s: SubmissionDetails) => {
              const latestRun = s.validation_runs?.[s.validation_runs.length - 1]
              return {
                id: s.id,
                user_id: s.contributor_id,
                file_url: s.assets?.[0]?.storage_key || null,
                content: s.content_payload ? JSON.stringify(s.content_payload) : null,
                ai_score: latestRun?.score ?? null,
                ai_feedback: latestRun?.findings?.map((f) => f.message).join('; ') || null,
                status: s.status.toLowerCase(),
                created_at: s.created_at,
              }
            })
            setSubmissions(mappedSubs)
            setLoading(false)
            return
          }
        } catch {
          // Fallback
        }

        const [{ data: ds }, { data: subs }] = await Promise.all([
          supabase.from('datasets').select('title, reward_per_task').eq('id', datasetId).single(),
          supabase
            .from('submissions')
            .select('*, users(wallet_address)')
            .eq('dataset_id', datasetId)
            .order('created_at', { ascending: false }),
        ])
        if (mounted) {
          if (ds) setDataset(ds)
          if (subs) setSubmissions(subs as Submission[])
          setLoading(false)
        }
      }
      void load()
    }
    return () => {
      mounted = false
    }
  }, [datasetId, supabase])

  const handleApprovePay = async (submission: Submission) => {
    if (!signer) {
      alert('Please connect your Web3 wallet first to sign the release transaction.')
      return
    }
    setPayingId(submission.id)
    try {
      const contributorWallet = submission.users?.wallet_address
      if (!contributorWallet) throw new Error('Contributor has no wallet address on file')

      const numericId = isNaN(Number(datasetId)) ? 1 : Number(datasetId)
      const txHash = await releasePayment(signer, numericId, contributorWallet)

      if (!isNaN(Number(datasetId))) {
        await supabase.from('payments').insert({
          submission_id: Number(submission.id),
          dataset_id: numericId,
          wallet_address: contributorWallet,
          amount: dataset?.reward_per_task || 0,
          tx_hash: txHash,
        })

        await supabase.from('submissions').update({ status: 'approved' }).eq('id', submission.id)
      }

      void fetchSubmissions()
      alert(`Escrow payout confirmed! Tx Hash: ${txHash}`)
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err)
      alert('Payment failed: ' + message)
    } finally {
      setPayingId(null)
    }
  }

  const truncateAddress = (addr: string) => `${addr.slice(0, 6)}...${addr.slice(-4)}`

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-3">
        <div className="w-12 h-12 rounded-full border-4 border-[#74E3B6] border-t-transparent animate-spin" />
        <p className="text-sm font-semibold text-[#3F5F52]">Loading dataset submissions...</p>
      </div>
    )
  }

  const approvedCount = submissions.filter((s) => s.status === 'approved').length
  const pendingCount = submissions.filter((s) => s.status === 'pending').length
  const rejectedCount = submissions.filter((s) => s.status === 'rejected').length

  return (
    <div className="space-y-8 pb-16">
      {/* Back button and Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div>
          <Link
            href="/dashboard"
            className="inline-flex items-center gap-1.5 text-xs font-bold uppercase tracking-wider text-[#3F5F52] hover:text-[#0D1F18] mb-3 transition-colors"
          >
            <span className="material-symbols-rounded text-base">arrow_back</span>
            Back to Dashboard
          </Link>
          <h1 className="font-bricolage text-3xl sm:text-4xl font-bold tracking-tight text-[#0D1F18]">
            {dataset?.title || `Dataset #${datasetId}`}
          </h1>
          <p className="text-sm sm:text-base text-[#3F5F52] mt-1 flex items-center gap-2">
            <span>Escrow payout:</span>
            <span className="font-bold text-[#0D1F18]">{dataset?.reward_per_task} cUSD</span>
            <span>per verified submission</span>
          </p>
        </div>

        <div className="flex items-center gap-3">
          <Button
            variant="outline"
            size="sm"
            className="rounded-full shadow-xs"
            onClick={() => fetchSubmissions()}
          >
            <span className="material-symbols-rounded text-lg">refresh</span>
            Refresh
          </Button>

          <a href={`/api/export/${datasetId}`} download>
            <Button size="sm" className="rounded-full font-bold shadow-sm">
              <span className="material-symbols-rounded text-lg">download</span>
              Export JSON
            </Button>
          </a>
        </div>
      </div>

      {/* Summary Stat Pills */}
      <div className="flex flex-wrap gap-3">
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white border border-[#BFE3D2] text-xs font-semibold text-[#0D1F18] shadow-xs">
          <span className="w-2 h-2 rounded-full bg-[#74E3B6]" />
          Total Submissions: <span className="font-bold">{submissions.length}</span>
        </div>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-emerald-50 border border-emerald-200 text-xs font-semibold text-emerald-800 shadow-xs">
          <span className="material-symbols-rounded text-base text-emerald-600">check_circle</span>
          Approved & Paid: <span className="font-bold">{approvedCount}</span>
        </div>
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-amber-50 border border-amber-200 text-xs font-semibold text-amber-800 shadow-xs">
          <span className="material-symbols-rounded text-base text-amber-600">pending</span>
          Pending Verification: <span className="font-bold">{pendingCount}</span>
        </div>
        {rejectedCount > 0 && (
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-red-50 border border-red-200 text-xs font-semibold text-red-800 shadow-xs">
            <span className="material-symbols-rounded text-base text-red-600">cancel</span>
            Rejected: <span className="font-bold">{rejectedCount}</span>
          </div>
        )}
      </div>

      {/* Submissions List */}
      {submissions.length === 0 ? (
        <Card className="rounded-[32px] border-2 border-dashed border-[#BFE3D2] bg-white/70 py-16 text-center max-w-xl mx-auto shadow-none">
          <CardContent className="flex flex-col items-center gap-4 text-center p-6">
            <div className="w-16 h-16 rounded-[22px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center text-[#3F5F52]">
              <span className="material-symbols-rounded text-3xl">inbox</span>
            </div>
            <div>
              <h3 className="font-bricolage text-2xl font-bold text-[#0D1F18]">
                No submissions received yet
              </h3>
              <p className="text-[#3F5F52] text-sm max-w-md mx-auto mt-1 leading-relaxed">
                Contributors will see this task in the marketplace. Once submissions arrive, they will appear here with AI validation scores.
              </p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {submissions.map((sub) => {
            const isApproved = sub.status === 'approved'
            const isRejected = sub.status === 'rejected'
            const isPending = !isApproved && !isRejected

            return (
              <Card
                key={sub.id}
                className="rounded-[28px] border border-[#BFE3D2] bg-white p-6 sm:p-7 shadow-xs hover:shadow-md transition-all space-y-4"
              >
                {/* Header row */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-[14px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center text-[#0D1F18]">
                      <span className="material-symbols-rounded text-xl">description</span>
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="font-bricolage text-lg font-bold text-[#0D1F18]">
                          Submission #{String(sub.id).slice(0, 8)}
                        </span>
                        {sub.users?.wallet_address && (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-[#EAFBF3] text-[11px] font-mono font-medium text-[#0D1F18] border border-[#BFE3D2]/70">
                            <span className="w-1.5 h-1.5 rounded-full bg-[#0B9E6B]" />
                            {truncateAddress(sub.users.wallet_address)}
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-[#3F5F52] mt-0.5">
                        Submitted {new Date(sub.created_at).toLocaleString()}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2.5">
                    {sub.ai_score !== null && (
                      <Badge
                        variant={sub.ai_score >= 80 ? 'success' : sub.ai_score >= 50 ? 'warning' : 'destructive'}
                        size="sm"
                        className="font-bold gap-1"
                      >
                        <span className="material-symbols-rounded text-sm">auto_awesome</span>
                        AI Score: {sub.ai_score}/100
                      </Badge>
                    )}

                    <Badge
                      variant={isApproved ? 'success' : isRejected ? 'destructive' : 'warning'}
                      size="sm"
                      className="uppercase font-bold text-[10px] tracking-wider"
                    >
                      {sub.status}
                    </Badge>
                  </div>
                </div>

                {/* Content Payload View */}
                {sub.content && (
                  <div className="rounded-[20px] bg-[#EAFBF3]/60 border border-[#BFE3D2]/70 p-4 text-sm text-[#0D1F18] leading-relaxed break-words font-mono text-xs">
                    {sub.content}
                  </div>
                )}

                {/* File Attachment */}
                {sub.file_url && (
                  <div className="flex items-center gap-2 text-xs text-[#3F5F52]">
                    <span className="material-symbols-rounded text-base text-[#0B9E6B]">
                      attach_file
                    </span>
                    <span className="font-semibold">Media asset:</span>
                    <a
                      href={sub.file_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-[#0B9E6B] underline font-mono"
                    >
                      {sub.file_url.split('/').pop()}
                    </a>
                  </div>
                )}

                {/* AI Pipeline Findings */}
                {sub.ai_feedback && (
                  <div className="rounded-[16px] bg-slate-50 border border-slate-200 p-3 text-xs text-[#3F5F52] flex items-start gap-2">
                    <span className="material-symbols-rounded text-base text-[#0B9E6B] shrink-0 mt-0.5">
                      psychology
                    </span>
                    <div>
                      <span className="font-bold text-[#0D1F18] mr-1">AI Pipeline Feedback:</span>
                      {sub.ai_feedback}
                    </div>
                  </div>
                )}

                {/* Escrow Release Footer */}
                {isPending && (
                  <div className="pt-2 flex justify-end">
                    <Button
                      onClick={() => handleApprovePay(sub)}
                      disabled={payingId === sub.id}
                      className="rounded-full font-bold shadow-xs"
                    >
                      <span className="material-symbols-rounded text-lg">payments</span>
                      {payingId === sub.id ? 'Releasing on Celo...' : 'Approve & Release Escrow'}
                    </Button>
                  </div>
                )}
              </Card>
            )
          })}
        </div>
      )}
    </div>
  )
}
