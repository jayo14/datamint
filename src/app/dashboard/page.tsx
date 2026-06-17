"use client"
import Link from "next/link"

import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardContent, CardDescription, CardFooter } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { fundDataset as fundDatasetOnChain } from '@/lib/blockchain'
import { ethers, type Signer, type Eip1193Provider } from 'ethers'
import { Plus, Database, Wallet, CheckCircle2, BarChart3, ArrowUpRight, ShieldCheck } from 'lucide-react'

interface Dataset {
  id: number;
  title: string;
  type: string;
  reward_per_task: number;
  total_required: number;
  completed_count: number;
  status: 'draft' | 'active' | 'completed';
}

interface WindowWithEthereum extends Window {
  ethereum?: Eip1193Provider;
}

export default function Dashboard() {
  const [datasets, setDatasets] = useState<Dataset[]>([])
  const [loading, setLoading] = useState(true)
  const [title, setTitle] = useState('')
  const [type, setType] = useState('text')
  const [reward, setReward] = useState('0.1')
  const [total, setTotal] = useState('100')
  const [fundingId, setFundingId] = useState<number | null>(null)
  const supabase = createClient()

  const fetchDatasets = useCallback(async () => {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

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
    let isMounted = true;
    const load = async () => {
        const { data: { user: authUser } } = await supabase.auth.getUser()
        if (!authUser || !isMounted) return

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
    return () => { isMounted = false };
  }, [supabase])

  const handleCreateDataset = async (e: React.FormEvent) => {
    e.preventDefault()
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data } = await supabase
      .from('datasets')
      .insert({
        creator_id: user.id,
        title,
        type,
        reward_per_task: parseFloat(reward),
        total_required: parseInt(total),
        status: 'draft'
      })
      .select()

    if (data) {
      setTitle('')
      fetchDatasets()
      alert("Dataset created successfully as draft!")
    }
  }

  const handleFund = async (dataset: Dataset) => {
    setFundingId(dataset.id)
    try {
      const win = window as unknown as WindowWithEthereum
      if (!win.ethereum) {
        alert("Please install a wallet like MiniPay or Metamask")
        return
      }

      const provider = new ethers.BrowserProvider(win.ethereum)
      const signer: Signer = await provider.getSigner()

      const txHash = await fundDatasetOnChain(
        signer,
        dataset.id,
        dataset.reward_per_task,
        dataset.total_required
      )

      if (txHash) {
        await supabase
          .from('datasets')
          .update({ status: 'active' })
          .eq('id', dataset.id)

        await supabase
          .from('payments')
          .insert({
            dataset_id: dataset.id,
            amount: dataset.reward_per_task * dataset.total_required,
            tx_hash: txHash,
            wallet_address: await signer.getAddress()
          })

        fetchDatasets()
      }
    } catch (error: unknown) {
      console.error(error)
      const message = error instanceof Error ? error.message : String(error)
      alert("Funding failed: " + message)
    } finally {
      setFundingId(null)
    }
  }

  return (
    <div className="space-y-10 pb-20 max-w-7xl mx-auto px-4 text-left">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 text-left">
        <div className="text-left">
            <h1 className="text-4xl font-black tracking-tight text-left leading-tight">Creator Dashboard</h1>
            <p className="text-muted-foreground font-medium text-left pt-1 text-base leading-relaxed">Manage your AI datasets and monitor contributions.</p>
        </div>
        <div className="flex items-center gap-3 text-left">
            <Button variant="outline" className="rounded-full h-11 border-primary/20 bg-primary/5 text-primary-foreground font-bold">
                <BarChart3 className="w-4 h-4 mr-2" />
                Analytics
            </Button>
            <Button className="rounded-full h-11 font-bold shadow-lg shadow-primary/20 bg-primary text-primary-foreground hover:opacity-90">
                <Plus className="w-4 h-4 mr-2" />
                New Request
            </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-left">
          <Card className="border-none shadow-sm bg-secondary/30 rounded-[2rem] p-2 text-left">
            <CardHeader className="flex flex-row items-center justify-between pb-2 text-left">
                <CardTitle className="text-sm font-bold uppercase tracking-widest text-muted-foreground text-left leading-none">Active Datasets</CardTitle>
                <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-primary-foreground text-left">
                    <Database className="w-4 h-4" />
                </div>
            </CardHeader>
            <CardContent className="text-left">
                <div className="text-3xl font-black text-left">{datasets.filter(d => d.status === 'active').length}</div>
                <p className="text-xs text-muted-foreground pt-1 text-left">Across multiple categories</p>
            </CardContent>
          </Card>
          <Card className="border-none shadow-sm bg-secondary/30 rounded-[2rem] p-2 text-left">
            <CardHeader className="flex flex-row items-center justify-between pb-2 text-left">
                <CardTitle className="text-sm font-bold uppercase tracking-widest text-muted-foreground text-left leading-none">Total Submissions</CardTitle>
                <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 text-left">
                    <CheckCircle2 className="w-4 h-4" />
                </div>
            </CardHeader>
            <CardContent className="text-left">
                <div className="text-3xl font-black text-left">
                    {datasets.reduce((acc, curr) => acc + (curr.completed_count || 0), 0)}
                </div>
                <p className="text-xs text-muted-foreground pt-1 text-left font-medium">Across all datasets</p>
            </CardContent>
          </Card>
          <Card className="border-none shadow-sm bg-secondary/30 rounded-[2rem] p-2 text-left">
            <CardHeader className="flex flex-row items-center justify-between pb-2 text-left">
                <CardTitle className="text-sm font-bold uppercase tracking-widest text-muted-foreground text-left leading-none">Funds in Escrow</CardTitle>
                <div className="w-8 h-8 rounded-full bg-amber-100 flex items-center justify-center text-amber-600 text-left">
                    <Wallet className="w-4 h-4" />
                </div>
            </CardHeader>
            <CardContent className="text-left">
                <div className="text-3xl font-black text-left">
                    {datasets.reduce((acc, curr) => acc + (curr.status === 'active' ? (curr.reward_per_task * curr.total_required) : 0), 0).toFixed(2)}
                    <span className="text-sm ml-1 font-bold text-base uppercase">cUSD</span>
                </div>
                <p className="text-xs text-muted-foreground pt-1 text-left text-base leading-none">Secured on Celo</p>
            </CardContent>
          </Card>
      </div>

      <Tabs defaultValue="overview" className="w-full text-left">
        <TabsList className="bg-secondary/50 p-1 rounded-full h-14 mb-8 text-left">
          <TabsTrigger value="overview" className="rounded-full px-8 font-bold data-[state=active]:bg-white data-[state=active]:text-primary-foreground data-[state=active]:shadow-sm transition-all h-12 text-sm">My Datasets</TabsTrigger>
          <TabsTrigger value="create" className="rounded-full px-8 font-bold data-[state=active]:bg-white data-[state=active]:text-primary-foreground data-[state=active]:shadow-sm transition-all h-12 text-sm">Create New Request</TabsTrigger>
        </TabsList>

        <TabsContent value="overview" className="mt-0 text-left">
          {loading ? (
            <div className="flex items-center justify-center py-20">
                <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
            </div>
          ) : datasets.length === 0 ? (
            <Card className="border-dashed border-2 bg-transparent rounded-[2.5rem] py-16 text-center text-left mx-auto max-w-2xl bg-white shadow-none">
              <CardContent className="flex flex-col items-center gap-4 text-center">
                <div className="w-20 h-20 bg-secondary rounded-full flex items-center justify-center text-muted-foreground mx-auto shadow-inner">
                    <Database className="w-10 h-10" />
                </div>
                <div className="space-y-1 text-center">
                    <h3 className="text-xl font-bold text-center leading-tight">No datasets found</h3>
                    <p className="text-muted-foreground max-w-[400px] text-center mx-auto text-base leading-relaxed">Start by creating your first dataset request to collect high-quality data from our global contributors.</p>
                </div>
                <Button className="rounded-full px-8 font-bold mt-4 h-12 text-base shadow-lg" onClick={() => fetchDatasets()}>Refresh</Button>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 text-left">
              {datasets.map((ds) => (
                <Card key={ds.id} className="border-none shadow-xl rounded-[2.5rem] overflow-hidden group hover:scale-[1.02] transition-all text-left flex flex-col bg-white">
                  <CardHeader className="bg-secondary/20 pb-6 pt-8 px-8 border-b border-border/50 text-left">
                    <div className="flex justify-between items-start mb-4 text-left">
                        <div className="w-12 h-12 rounded-2xl bg-white shadow-inner flex items-center justify-center">
                            <Database className="w-6 h-6 text-primary-foreground" />
                        </div>
                        <Badge className={`px-3 py-1 rounded-full font-bold border-none ${ds.status === 'active' ? 'bg-green-100 text-green-600' : 'bg-amber-100 text-amber-600'}`}>
                            {ds.status.toUpperCase()}
                        </Badge>
                    </div>
                    <CardTitle className="text-2xl font-black leading-tight tracking-tight group-hover:text-primary-foreground transition-colors text-left leading-none">{ds.title}</CardTitle>
                    <CardDescription className="text-sm font-bold uppercase tracking-wider text-primary-foreground/60 pt-2 text-left leading-none">
                        {ds.type} • {ds.reward_per_task} cUSD per task
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="p-8 space-y-6 text-left flex-1">
                    <div className="space-y-3 text-left">
                      <div className="flex justify-between text-sm font-bold text-left">
                        <span className="text-muted-foreground text-left leading-none">Progress</span>
                        <span className="leading-none text-sm">{ds.completed_count || 0} / {ds.total_required} <span className="text-muted-foreground font-medium ml-1">({Math.round(((ds.completed_count || 0) / ds.total_required) * 100)}%)</span></span>
                      </div>
                      <div className="h-3 bg-secondary rounded-full overflow-hidden shadow-inner p-[2px] text-left">
                        <div
                          className="h-full bg-primary rounded-full transition-all duration-1000 shadow-[0_0_8px_rgba(var(--primary),0.4)]"
                          style={{ width: `${Math.max(((ds.completed_count || 0) / ds.total_required) * 100, 4)}%` }}
                        />
                      </div>
                    </div>
                  </CardContent>
                  <CardFooter className="px-8 pb-8 pt-0 text-left">
                    {ds.status === 'draft' && (
                      <Button
                        className="w-full h-12 rounded-2xl font-bold shadow-lg shadow-primary/20 h-12 text-primary-foreground"
                        disabled={fundingId === ds.id}
                        onClick={() => handleFund(ds)}
                      >
                        {fundingId === ds.id ? 'Funding...' : 'Fund & Activate'}
                      </Button>
                    )}
                    {ds.status === 'active' && (
                      <>
                        <Link href={} className="w-full">
                          <Button className="w-full h-12 rounded-2xl font-bold h-12 text-primary-foreground bg-primary hover:opacity-90 transition-opacity flex items-center justify-center gap-2" variant="default">
                            View Submissions
                            <ArrowUpRight className="w-4 h-4" />
                          </Button>
                        </Link>
                        <a href={} download className="w-full">
                          <Button variant="ghost" size="sm" className="w-full mt-2 rounded-2xl font-bold text-xs h-10">
                            Export Dataset
                          </Button>
                        </a>
                      </>
                    )}
                  </CardFooter>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>            <Card className="border-none shadow-xl rounded-[2.5rem] bg-gradient-to-br from-primary/10 to-secondary/10 p-8 mt-8 border border-primary/20">
              <div className="flex flex-col md:flex-row items-center gap-6">
                <div className="w-16 h-16 bg-white rounded-2xl flex items-center justify-center shadow-lg">
                  <ShieldCheck className="w-10 h-10 text-primary-foreground" />
                </div>
                <div className="flex-1 text-center md:text-left">
                  <h3 className="text-xl font-bold leading-tight">Hackathon Requirement: ERC-8004</h3>
                  <p className="text-muted-foreground pt-1">Register DataMint as an AI Agent on Celo to qualify for Track 3 prizes.</p>
                </div>
                <Link href="/dashboard/register-agent">
                  <Button className="rounded-full px-8 font-bold h-12 shadow-lg">Register Now</Button>
                </Link>
              </div>
            </Card>


        <TabsContent value="create" className="mt-0 text-left">
          <Card className="border-none shadow-2xl rounded-[3rem] overflow-hidden text-left bg-white">
            <CardHeader className="bg-secondary/20 p-12 text-center border-b">
              <div className="w-20 h-20 bg-white rounded-3xl flex items-center justify-center mx-auto mb-6 shadow-xl shadow-primary/10 text-left">
                <Database className="w-10 h-10 text-primary-foreground mx-auto" />
              </div>
              <CardTitle className="text-4xl font-black tracking-tight text-center leading-none">Create Dataset Request</CardTitle>
              <CardDescription className="text-lg max-w-[500px] mx-auto pt-4 text-center text-muted-foreground leading-relaxed">Define your requirements and budget. Our contributors will do the rest.</CardDescription>
            </CardHeader>
            <form onSubmit={handleCreateDataset} className="text-left">
              <CardContent className="p-12 space-y-8 text-left">
                <div className="space-y-4 text-left">
                  <Label htmlFor="title" className="text-lg font-bold text-left block">Request Title</Label>
                  <Input
                    id="title"
                    placeholder="e.g. Nigerian English Accent Voice Data"
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    required
                    className="h-14 rounded-2xl bg-secondary/50 border-none px-6 text-lg focus-visible:ring-primary h-14 text-base"
                  />
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-8 text-left">
                  <div className="space-y-4 text-left text-base">
                    <Label htmlFor="type" className="text-lg font-bold text-left block">Data Type</Label>
                    <select
                      id="type"
                      className="flex h-14 w-full rounded-2xl bg-secondary/50 border-none px-6 text-lg font-medium ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 appearance-none h-14 text-base"
                      value={type}
                      onChange={(e) => setType(e.target.value)}
                    >
                      <option value="text">Text (Labels, NLP)</option>
                      <option value="voice">Voice (Audio samples)</option>
                      <option value="image">Image (CV Training)</option>
                    </select>
                  </div>
                  <div className="space-y-4 text-left text-base">
                    <Label htmlFor="reward" className="text-lg font-bold text-left block">Reward per Task (cUSD)</Label>
                    <div className="relative text-left">
                        <Input
                            id="reward"
                            type="number"
                            step="0.01"
                            value={reward}
                            onChange={(e) => setReward(e.target.value)}
                            required
                            className="h-14 rounded-2xl bg-secondary/50 border-none pl-6 pr-16 text-lg focus-visible:ring-primary h-14 text-base"
                        />
                        <div className="absolute right-6 top-1/2 -translate-y-1/2 font-bold text-primary-foreground text-sm uppercase leading-none">cUSD</div>
                    </div>
                  </div>
                </div>

                <div className="space-y-4 text-left text-base">
                  <Label htmlFor="total" className="text-lg font-bold text-left text-base block">Total Submissions Needed</Label>
                  <Input
                    id="total"
                    type="number"
                    value={total}
                    onChange={(e) => setTotal(e.target.value)}
                    required
                    className="h-14 rounded-2xl bg-secondary/50 border-none px-6 text-lg focus-visible:ring-primary h-14 text-base"
                  />
                </div>

                <div className="p-6 rounded-3xl bg-primary/5 border border-primary/20 flex items-start gap-4 text-left">
                    <div className="p-2 rounded-xl bg-primary/20 text-primary-foreground mt-1 text-left flex items-center justify-center">
                        <Wallet className="w-5 h-5" />
                    </div>
                    <div className="text-left">
                        <p className="font-bold text-primary-foreground text-left text-base leading-none">Estimated Total Funding</p>
                        <p className="text-2xl font-black text-primary-foreground text-left pt-2 leading-none">{(parseFloat(reward) * parseInt(total)).toFixed(2)} cUSD</p>
                        <p className="text-xs text-muted-foreground pt-1 font-medium italic text-left leading-tight">Tokens will be held in the DataMint Escrow contract.</p>
                    </div>
                </div>
              </CardContent>
              <CardFooter className="p-12 pt-0 text-left">
                <Button type="submit" className="w-full h-16 rounded-[2rem] text-xl font-bold shadow-xl shadow-primary/20 h-16 text-lg bg-primary text-primary-foreground hover:opacity-90">Create Dataset Request</Button>
              </CardFooter>
            </form>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
