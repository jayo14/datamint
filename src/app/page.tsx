import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Database, Coins, Users, Zap, ArrowRight, ShieldCheck } from 'lucide-react'

export default function Home() {
  return (
    <div className="flex flex-col gap-24 py-12 md:py-24">
      <section className="text-center space-y-8 max-w-4xl mx-auto">
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20 text-primary-foreground text-sm font-bold uppercase tracking-wider mb-4 animate-in fade-in slide-in-from-bottom-4 duration-1000">
            <ShieldCheck className="w-4 h-4" />
            <span>On-Chain & Verified</span>
        </div>
        <h1 className="text-5xl md:text-7xl font-black tracking-tighter leading-[1.1]">Turn Human Input into <br /><span className="text-primary italic">AI Datasets</span></h1>
        <p className="text-xl md:text-2xl text-muted-foreground max-w-[700px] mx-auto leading-relaxed">The fastest way to collect high-quality data for AI models, with instant Celo payouts for contributors worldwide.</p>
        <div className="flex flex-col sm:flex-row justify-center gap-4 pt-8">
          <Link href="/login"><Button size="lg" className="px-10 h-16 rounded-2xl text-xl font-bold bg-primary text-primary-foreground shadow-xl shadow-primary/20">Start Building<ArrowRight className="ml-2 w-6 h-6" /></Button></Link>
          <Button size="lg" variant="outline" className="px-10 h-16 rounded-2xl text-xl font-bold border-2 hover:bg-secondary">Learn More</Button>
        </div>
      </section>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
        {[
          { icon: Zap, title: "Instant Payouts", desc: "Get paid in cUSD immediately after AI validation." },
          { icon: Database, title: "Structured Data", desc: "Export AI-ready datasets in CSV or JSON format." },
          { icon: Coins, title: "On-Chain Escrow", desc: "Trustless payments powered by Celo smart contracts." },
          { icon: Users, title: "Global Crowd", desc: "Access diverse human data from anywhere in the world." }
        ].map((item, i) => (
          <Card key={i} className="border-none shadow-xl rounded-[2.5rem] bg-white p-2">
            <CardHeader className="space-y-4">
              <div className="w-16 h-16 rounded-2xl flex items-center justify-center bg-primary/10 text-primary-foreground"><item.icon className="w-8 h-8" /></div>
              <div><CardTitle className="text-2xl font-black">{item.title}</CardTitle><CardDescription className="text-base pt-2">{item.desc}</CardDescription></div>
            </CardHeader>
          </Card>
        ))}
      </div>
      <section className="bg-secondary/40 rounded-[3.5rem] p-8 md:p-20 border border-white/50 backdrop-blur-sm">
        <div className="grid lg:grid-cols-2 gap-16 items-center">
          <div className="space-y-10">
            <h2 className="text-4xl md:text-5xl font-black tracking-tight leading-tight">How it Works</h2>
            <div className="space-y-8">
              {[
                { step: 1, title: "Create & Fund", desc: "Define your dataset needs and fund the escrow contract with cUSD." },
                { step: 2, title: "Contribute", desc: "Contributors submit voice, image, or text data via mobile or MiniPay." },
                { step: 3, title: "AI Validates", desc: "Our AI layer checks quality and relevance instantly using GPT-4o." },
                { step: 4, title: "Paid Instantly", desc: "Smart contract releases funds to the contributor's wallet." }
              ].map((item, i) => (
                <div key={i} className="flex gap-6 group">
                  <div className="flex-none w-12 h-12 rounded-2xl bg-primary text-primary-foreground flex items-center justify-center font-black text-xl shadow-lg shadow-primary/20">{item.step}</div>
                  <div><p className="font-black text-2xl mb-1">{item.title}</p><p className="text-muted-foreground text-lg leading-relaxed">{item.desc}</p></div>
                </div>
              ))}
            </div>
          </div>
          <div className="relative">
            <div className="absolute -inset-4 bg-primary/20 blur-3xl rounded-full opacity-50" />
            <div className="relative bg-white rounded-[3rem] p-10 border shadow-2xl space-y-8">
              <div className="flex justify-between items-center border-b pb-6"><span className="font-black text-xl">Sample Task</span><Badge className="bg-primary/10 text-primary-foreground border-none px-4 py-1 rounded-full text-sm font-bold">VOICE</Badge></div>
              <p className="text-lg font-medium leading-relaxed italic">"Record yourself saying: 'The quick brown fox jumps over the lazy dog' in your native accent."</p>
              <div className="flex justify-between items-center text-sm font-bold text-muted-foreground bg-secondary/50 p-4 rounded-2xl"><span className="flex items-center gap-2"><Coins className="w-4 h-4" /> Reward: 0.50 cUSD</span><span className="flex items-center gap-2"><Zap className="w-4 h-4" /> Time: ~30s</span></div>
              <Button className="w-full h-16 rounded-[1.5rem] text-xl font-black bg-primary text-primary-foreground shadow-lg shadow-primary/10">Try Demo Task</Button>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
