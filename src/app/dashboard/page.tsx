"use client"

import Link from "next/link"
import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { api, type Campaign } from '@/lib/api'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardContent, CardDescription, CardFooter } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { fundDataset as fundDatasetOnChain } from '@/lib/blockchain'
import { ethers, type Signer, type Eip1193Provider } from 'ethers'

interface Dataset {
  id: number | string
  title: string
  type: string
  reward_per_task: number
  total_required: number
  completed_count: number
  status: 'draft' | 'active' | 'completed' | string
}

interface WindowWithEthereum extends Window {
  ethereum?: Eip1193Provider
}

export default function Dashboard() {
  const [datasets, setDatasets] = useState<Dataset[]>([])
  const [loading, setLoading] = useState(true)
  const [title, setTitle] = useState('')
  const [type, setType] = useState('text')
  const [reward, setReward] = useState('0.1')
  const [total, setTotal] = useState('100')
  const [fundingId, setFundingId] = useState<number | string | null>(null)
  const [activeTab, setActiveTab] = useState('overview')
  const supabase = createClient()

  const fetchDatasets = useCallback(async () => {
    try {
      const res = await api.getMyCampaigns()
      if (res && res.items && res.items.length > 0) {
        const backendDatasets: Dataset[] = res.items.map((c: Campaign) => ({
          id: c.id,
          title: c.title,
          type: c.data_type.toLowerCase(),
          reward_per_task:
            typeof c.reward_per_submission === 'string'
              ? parseFloat(c.reward_per_submission)
              : c.reward_per_submission,
          total_required: c.target_submissions,
          completed_count: c.current_submissions,
          status: c.status.toLowerCase(),
        }))
        setDatasets(backendDatasets)
        setLoading(false)
        return
      }
    } catch {
      // Fallback to supabase
    }

    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) {
      setLoading(false)
      return
    }

    const { data } = await supabase
      .from('datasets')
      .select('*')
      .eq('creator_id', user.id)
      .order('created_at', { ascending: false })

    if (data) {
      setDatasets(data as Dataset[])
    }
    setLoading(false)
  }, [supabase])

  useEffect(() => {
    let isMounted = true
    const load = async () => {
      try {
        const res = await api.getMyCampaigns()
        if (res && res.items && res.items.length > 0 && isMounted) {
          const backendDatasets: Dataset[] = res.items.map((c: Campaign) => ({
            id: c.id,
            title: c.title,
            type: c.data_type.toLowerCase(),
            reward_per_task:
              typeof c.reward_per_submission === 'string'
                ? parseFloat(c.reward_per_submission)
                : c.reward_per_submission,
            total_required: c.target_submissions,
            completed_count: c.current_submissions,
            status: c.status.toLowerCase(),
          }))
          setDatasets(backendDatasets)
          setLoading(false)
          return
        }
      } catch {
        // Fallback
      }

      const {
        data: { user: authUser },
      } = await supabase.auth.getUser()
      if (!authUser || !isMounted) {
        if (isMounted) setLoading(false)
        return
      }

      const { data } = await supabase
        .from('datasets')
        .select('*')
        .eq('creator_id', authUser.id)
        .order('created_at', { ascending: false })

      if (data && isMounted) {
        setDatasets(data as Dataset[])
      }
      if (isMounted) setLoading(false)
    }
    load()
    return () => {
      isMounted = false
    }
  }, [supabase])

  const handleCreateDataset = async (e: React.FormEvent) => {
    e.preventDefault()

    try {
      const created = await api.createCampaign({
        title,
        description: `Campaign for ${title}`,
        instructions: `Please provide high-quality ${type} data.`,
        data_type: type.toUpperCase() as 'TEXT' | 'VOICE' | 'IMAGE',
        reward_per_submission: parseFloat(reward),
        target_submissions: parseInt(total),
      })
      if (created) {
        setTitle('')
        fetchDatasets()
        setActiveTab('overview')
        alert('Dataset campaign created successfully on backend!')
        return
      }
    } catch {
      // Fallback to supabase
    }

    const {
      data: { user },
    } = await supabase.auth.getUser()
    if (!user) return

    const { data } = await supabase
      .from('datasets')
      .insert({
        creator_id: user.id,
        title,
        type,
        reward_per_task: parseFloat(reward),
        total_required: parseInt(total),
        status: 'draft',
      })
      .select()

    if (data) {
      setTitle('')
      fetchDatasets()
      setActiveTab('overview')
      alert('Dataset created successfully as draft!')
    }
  }

  const handleFund = async (dataset: Dataset) => {
    setFundingId(dataset.id)
    try {
      const win = window as unknown as WindowWithEthereum
      if (!win.ethereum) {
        alert('Please install a wallet like MiniPay or Metamask')
        return
      }

      const provider = new ethers.BrowserProvider(win.ethereum)
      const signer: Signer = await provider.getSigner()

      if (typeof dataset.id === 'string') {
        const fundingParams = await api.submitCampaignForFunding(dataset.id)
        alert(
          `Campaign parameters ready for on-chain escrow: ${fundingParams.onchain_params.campaign_id_bytes32}. Please confirm in your connected wallet.`
        )
      }

      const numericId = typeof dataset.id === 'number' ? dataset.id : 1
      const txHash = await fundDatasetOnChain(
        signer,
        numericId,
        dataset.reward_per_task,
        dataset.total_required
      )

      if (txHash) {
        if (typeof dataset.id === 'number') {
          await supabase
            .from('datasets')
            .update({ status: 'active' })
            .eq('id', dataset.id)

          await supabase.from('payments').insert({
            dataset_id: dataset.id,
            amount: dataset.reward_per_task * dataset.total_required,
            tx_hash: txHash,
            wallet_address: await signer.getAddress(),
          })
        }
        fetchDatasets()
        alert(`Funding successful! Transaction Hash: ${txHash}`)
      }
    } catch (error: unknown) {
      console.error(error)
      const message = error instanceof Error ? error.message : String(error)
      alert('Funding failed: ' + message)
    } finally {
      setFundingId(null)
    }
  }

  const activeCount = datasets.filter((d) => d.status === 'active').length
  const totalSubmissions = datasets.reduce(
    (acc, curr) => acc + (curr.completed_count || 0),
    0
  )
  const escrowTotal = datasets
    .reduce(
      (acc, curr) =>
        acc +
        (curr.status === 'active'
          ? curr.reward_per_task * curr.total_required
          : 0),
      0
    )
    .toFixed(2)

  const getTypeIcon = (dType: string) => {
    switch (dType.toLowerCase()) {
      case 'voice':
        return 'mic'
      case 'image':
        return 'image'
      default:
        return 'article'
    }
  }

  return (
    <div className="space-y-8 sm:space-y-10 pb-16">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div>
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-white border border-[#BFE3D2] shadow-xs mb-3">
            <span className="w-2 h-2 rounded-full bg-[#0B9E6B] animate-pulse" />
            <span className="material-symbols-rounded text-sm text-[#0D1F18]">
              shield_person
            </span>
            <span className="text-xs font-bold uppercase tracking-wider text-[#3F5F52]">
              Creator Protocol Portal
            </span>
          </div>
          <h1 className="font-bricolage text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#0D1F18]">
            Creator Dashboard
          </h1>
          <p className="text-[#3F5F52] text-base sm:text-lg mt-1 max-w-2xl leading-relaxed">
            Manage your AI training datasets, monitor incoming submissions, and fund smart escrows on Celo.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <Button
            variant="outline"
            className="rounded-full shadow-xs"
            onClick={() => fetchDatasets()}
          >
            <span className="material-symbols-rounded text-lg">refresh</span>
            Refresh
          </Button>

          <Button
            className="rounded-full font-bold shadow-md"
            onClick={() => setActiveTab('create')}
          >
            <span className="material-symbols-rounded text-lg">add_circle</span>
            New Request
          </Button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        <Card className="rounded-[28px] border-[#BFE3D2] bg-white p-6 shadow-xs hover:shadow-md transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between p-0 pb-3">
            <CardTitle className="text-xs font-bold uppercase tracking-wider text-[#3F5F52]">
              Active Datasets
            </CardTitle>
            <div className="w-11 h-11 rounded-[16px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center text-[#0D1F18]">
              <span className="material-symbols-rounded text-xl">dataset</span>
            </div>
          </CardHeader>
          <CardContent className="p-0">
            <div className="font-bricolage text-3xl sm:text-4xl font-bold text-[#0D1F18]">
              {activeCount}
            </div>
            <p className="text-xs text-[#3F5F52] mt-1 font-medium">
              Live on DataMint decentralized marketplace
            </p>
          </CardContent>
        </Card>

        <Card className="rounded-[28px] border-[#BFE3D2] bg-white p-6 shadow-xs hover:shadow-md transition-shadow">
          <CardHeader className="flex flex-row items-center justify-between p-0 pb-3">
            <CardTitle className="text-xs font-bold uppercase tracking-wider text-[#3F5F52]">
              Total Submissions
            </CardTitle>
            <div className="w-11 h-11 rounded-[16px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center text-[#0B9E6B]">
              <span className="material-symbols-rounded text-xl">verified</span>
            </div>
          </CardHeader>
          <CardContent className="p-0">
            <div className="font-bricolage text-3xl sm:text-4xl font-bold text-[#0D1F18]">
              {totalSubmissions}
            </div>
            <p className="text-xs text-[#3F5F52] mt-1 font-medium">
              Contributions verified by AI pipeline
            </p>
          </CardContent>
        </Card>

        <Card className="rounded-[28px] border-[#BFE3D2] bg-white p-6 shadow-xs hover:shadow-md transition-shadow sm:col-span-2 lg:col-span-1">
          <CardHeader className="flex flex-row items-center justify-between p-0 pb-3">
            <CardTitle className="text-xs font-bold uppercase tracking-wider text-[#3F5F52]">
              Funds in Escrow
            </CardTitle>
            <div className="w-11 h-11 rounded-[16px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center text-[#0D1F18]">
              <span className="material-symbols-rounded text-xl">shield_lock</span>
            </div>
          </CardHeader>
          <CardContent className="p-0">
            <div className="font-bricolage text-3xl sm:text-4xl font-bold text-[#0D1F18] flex items-baseline gap-1.5">
              {escrowTotal}
              <span className="text-sm font-bold uppercase tracking-wider text-[#3F5F52]">
                cUSD
              </span>
            </div>
            <p className="text-xs text-[#3F5F52] mt-1 font-medium">
              Secured on Celo smart contracts
            </p>
          </CardContent>
        </Card>
      </div>

      {/* ERC-8004 Hackathon Banner */}
      <div className="rounded-[32px] bg-gradient-to-r from-white via-white to-[#EAFBF3] border border-[#BFE3D2] p-6 sm:p-8 shadow-xs flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-[20px] bg-[#74E3B6] text-[#0D1F18] flex items-center justify-center shrink-0 shadow-sm">
            <span className="material-symbols-rounded text-3xl">smart_toy</span>
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-bricolage text-xl font-bold text-[#0D1F18]">
                ERC-8004 AI Agent Identity
              </h3>
              <Badge variant="mint" size="sm">Celo Track 3</Badge>
            </div>
            <p className="text-sm text-[#3F5F52] mt-0.5 leading-relaxed">
              Register DataMint as an on-chain AI Agent on Celo to qualify for track prizes and unlock automated task validation.
            </p>
          </div>
        </div>

        <Link href="/dashboard/register-agent" className="shrink-0">
          <Button variant="outline" className="rounded-full font-bold border-[#BFE3D2] hover:border-[#74E3B6] shadow-xs">
            <span className="material-symbols-rounded text-lg">verified_user</span>
            Register Agent
          </Button>
        </Link>
      </div>

      {/* Tabs Navigation */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="mb-6">
          <TabsTrigger value="overview">
            <span className="material-symbols-rounded text-lg mr-1.5">folder_open</span>
            My Datasets ({datasets.length})
          </TabsTrigger>
          <TabsTrigger value="create">
            <span className="material-symbols-rounded text-lg mr-1.5">add_circle</span>
            Create New Request
          </TabsTrigger>
        </TabsList>

        {/* Datasets Overview */}
        <TabsContent value="overview">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-24 gap-3">
              <div className="w-12 h-12 rounded-full border-4 border-[#74E3B6] border-t-transparent animate-spin" />
              <p className="text-sm font-semibold text-[#3F5F52]">Loading your datasets...</p>
            </div>
          ) : datasets.length === 0 ? (
            <Card className="rounded-[32px] border-2 border-dashed border-[#BFE3D2] bg-white/70 py-16 text-center max-w-xl mx-auto shadow-none">
              <CardContent className="flex flex-col items-center gap-4 text-center p-6">
                <div className="w-16 h-16 rounded-[22px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center text-[#3F5F52]">
                  <span className="material-symbols-rounded text-3xl">database</span>
                </div>
                <div>
                  <h3 className="font-bricolage text-2xl font-bold text-[#0D1F18]">
                    No datasets found
                  </h3>
                  <p className="text-[#3F5F52] text-sm max-w-md mx-auto mt-1 leading-relaxed">
                    Create your first AI dataset campaign to start collecting high-quality labeled voice, text, or visual data.
                  </p>
                </div>
                <Button
                  className="rounded-full px-8 font-bold mt-2 shadow-sm"
                  onClick={() => setActiveTab('create')}
                >
                  <span className="material-symbols-rounded text-lg">add</span>
                  Create Your First Dataset
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {datasets.map((ds) => {
                const percent = Math.min(
                  Math.round(((ds.completed_count || 0) / (ds.total_required || 1)) * 100),
                  100
                )
                const isActive = ds.status === 'active'

                return (
                  <Card
                    key={ds.id}
                    className="rounded-[32px] border border-[#BFE3D2] bg-white p-6 sm:p-7 shadow-xs hover:shadow-lg transition-all flex flex-col justify-between"
                  >
                    <div>
                      {/* Top status bar */}
                      <div className="flex items-center justify-between gap-3 mb-5">
                        <div className="w-12 h-12 rounded-[16px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center text-[#0D1F18]">
                          <span className="material-symbols-rounded text-2xl">
                            {getTypeIcon(ds.type)}
                          </span>
                        </div>
                        <Badge
                          variant={isActive ? 'success' : 'warning'}
                          size="sm"
                          className="font-bold tracking-wider uppercase text-[11px]"
                        >
                          {isActive ? 'Active' : 'Draft Escrow'}
                        </Badge>
                      </div>

                      {/* Title and details */}
                      <CardTitle className="font-bricolage text-xl sm:text-2xl font-bold text-[#0D1F18] line-clamp-2 leading-snug">
                        {ds.title}
                      </CardTitle>

                      <div className="flex items-center gap-2 mt-2">
                        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#EAFBF3] text-xs font-semibold text-[#0D1F18] border border-[#BFE3D2]">
                          <span className="material-symbols-rounded text-sm text-[#0B9E6B]">
                            monetization_on
                          </span>
                          {ds.reward_per_task} cUSD / task
                        </span>
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-slate-50 text-[11px] font-semibold text-[#3F5F52] border border-slate-200 uppercase">
                          {ds.type}
                        </span>
                      </div>

                      {/* Progress bar */}
                      <div className="mt-6 space-y-2">
                        <div className="flex justify-between text-xs font-semibold text-[#3F5F52]">
                          <span>Progress</span>
                          <span className="text-[#0D1F18] font-bold">
                            {ds.completed_count || 0} / {ds.total_required}{' '}
                            <span className="text-[#3F5F52] font-normal">({percent}%)</span>
                          </span>
                        </div>
                        <Progress value={percent} className="h-2.5" />
                      </div>
                    </div>

                    {/* Footer Actions */}
                    <CardFooter className="p-0 pt-6 mt-6 border-t border-[#BFE3D2]/40 flex flex-col gap-2.5">
                      {!isActive ? (
                        <Button
                          className="w-full rounded-full font-bold shadow-sm"
                          disabled={fundingId === ds.id}
                          onClick={() => handleFund(ds)}
                        >
                          <span className="material-symbols-rounded text-lg">shield_lock</span>
                          {fundingId === ds.id ? 'Funding on Celo...' : 'Fund & Activate Escrow'}
                        </Button>
                      ) : (
                        <>
                          <Link
                            href={`/dashboard/submissions/${ds.id}`}
                            className="w-full"
                          >
                            <Button className="w-full rounded-full font-bold shadow-sm">
                              <span>View Submissions</span>
                              <span className="material-symbols-rounded text-lg">
                                arrow_forward
                              </span>
                            </Button>
                          </Link>
                          <a
                            href={`/api/export/${ds.id}`}
                            download
                            className="w-full"
                          >
                            <Button
                              variant="outline"
                              size="sm"
                              className="w-full rounded-full text-xs font-semibold"
                            >
                              <span className="material-symbols-rounded text-base">
                                download
                              </span>
                              Export Dataset JSON
                            </Button>
                          </a>
                        </>
                      )}
                    </CardFooter>
                  </Card>
                )
              })}
            </div>
          )}
        </TabsContent>

        {/* Create Campaign Tab */}
        <TabsContent value="create">
          <Card className="rounded-[36px] sm:rounded-[44px] border border-[#BFE3D2] bg-white p-6 sm:p-12 shadow-sm max-w-3xl mx-auto">
            <div className="text-center mb-8">
              <div className="w-16 h-16 rounded-[22px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center mx-auto mb-4 text-[#0D1F18] shadow-xs">
                <span className="material-symbols-rounded text-3xl">add_box</span>
              </div>
              <h2 className="font-bricolage text-2xl sm:text-3xl font-bold text-[#0D1F18]">
                Create Dataset Request
              </h2>
              <p className="text-sm sm:text-base text-[#3F5F52] mt-1 max-w-lg mx-auto leading-relaxed">
                Define your collection specifications and escrow budget. Human contributors worldwide will deliver validated samples.
              </p>
            </div>

            <form onSubmit={handleCreateDataset} className="space-y-6">
              <div className="space-y-2">
                <Label htmlFor="title">Dataset Title</Label>
                <Input
                  id="title"
                  placeholder="e.g. Nigerian English Accent Voice Samples"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  required
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                <div className="space-y-2">
                  <Label htmlFor="type">Data Modality</Label>
                  <select
                    id="type"
                    className="h-12 w-full rounded-full border border-[#BFE3D2] bg-white px-5 py-2 text-sm text-[#0D1F18] outline-none transition-all focus:border-[#74E3B6] focus:ring-2 focus:ring-[#74E3B6]/30 cursor-pointer"
                    value={type}
                    onChange={(e) => setType(e.target.value)}
                  >
                    <option value="text">Text (Labels, NLP Prompts)</option>
                    <option value="voice">Voice (Audio Utterances)</option>
                    <option value="image">Image (Computer Vision)</option>
                  </select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="reward">Reward per Task (cUSD)</Label>
                  <div className="relative">
                    <Input
                      id="reward"
                      type="number"
                      step="0.01"
                      value={reward}
                      onChange={(e) => setReward(e.target.value)}
                      required
                      className="pr-16 font-mono"
                    />
                    <div className="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-[#3F5F52] uppercase pointer-events-none">
                      cUSD
                    </div>
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="total">Target Submissions Count</Label>
                <Input
                  id="total"
                  type="number"
                  min="1"
                  value={total}
                  onChange={(e) => setTotal(e.target.value)}
                  required
                  className="font-mono"
                />
              </div>

              {/* Escrow Calculation Preview */}
              <div className="rounded-[24px] bg-[#EAFBF3] border border-[#BFE3D2] p-5 flex items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-[#74E3B6]/30 flex items-center justify-center text-[#0D1F18]">
                    <span className="material-symbols-rounded text-xl">shield_lock</span>
                  </div>
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-wider text-[#3F5F52]">
                      Estimated Escrow Deposit
                    </p>
                    <p className="font-bricolage text-2xl font-bold text-[#0D1F18]">
                      {(parseFloat(reward || '0') * parseInt(total || '0')).toFixed(2)} cUSD
                    </p>
                  </div>
                </div>
                <Badge variant="mint" size="sm">Celo Escrow</Badge>
              </div>

              <Button
                type="submit"
                className="w-full h-14 rounded-full font-bricolage text-lg font-bold shadow-md"
              >
                <span className="material-symbols-rounded text-xl">check_circle</span>
                Create Dataset Request
              </Button>
            </form>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
