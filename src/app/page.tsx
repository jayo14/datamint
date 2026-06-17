import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Database, Coins, Users, Zap } from 'lucide-react'

export default function Home() {
  return (
    <div className="flex flex-col gap-16 py-8 md:py-12">
      <section className="text-center space-y-4">
        <h1 className="text-4xl md:text-6xl font-bold tracking-tighter">
          Turn Human Input into <br />
          <span className="text-primary">AI Datasets On-Chain</span>
        </h1>
        <p className="text-xl text-muted-foreground max-w-[700px] mx-auto">
          The fastest way to collect high-quality data for AI models, with instant Celo payouts for contributors.
        </p>
        <div className="flex justify-center gap-4 pt-4">
          <Link href="/login">
            <Button size="lg" className="px-8">Get Started</Button>
          </Link>
          <Button size="lg" variant="outline" className="px-8">Learn More</Button>
        </div>
      </section>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card>
          <CardHeader>
            <Zap className="w-10 h-10 text-primary mb-2" />
            <CardTitle>Instant Payouts</CardTitle>
            <CardDescription>Get paid in cUSD immediately after AI validation.</CardDescription>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader>
            <Database className="w-10 h-10 text-primary mb-2" />
            <CardTitle>Structured Data</CardTitle>
            <CardDescription>Export AI-ready datasets in CSV or JSON format.</CardDescription>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader>
            <Coins className="w-10 h-10 text-primary mb-2" />
            <CardTitle>On-Chain Escrow</CardTitle>
            <CardDescription>Trustless payments powered by Celo smart contracts.</CardDescription>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader>
            <Users className="w-10 h-10 text-primary mb-2" />
            <CardTitle>Global Crowd</CardTitle>
            <CardDescription>Access diverse human data from anywhere in the world.</CardDescription>
          </CardHeader>
        </Card>
      </div>

      <section className="bg-secondary/50 rounded-3xl p-8 md:p-12">
        <div className="grid md:grid-cols-2 gap-12 items-center">
          <div className="space-y-6">
            <h2 className="text-3xl font-bold">How it Works</h2>
            <div className="space-y-4">
              <div className="flex gap-4">
                <div className="flex-none w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-bold">1</div>
                <div>
                  <p className="font-bold">Create & Fund</p>
                  <p className="text-muted-foreground text-sm">Define your dataset needs and fund the escrow contract.</p>
                </div>
              </div>
              <div className="flex gap-4">
                <div className="flex-none w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-bold">2</div>
                <div>
                  <p className="font-bold">Contribute</p>
                  <p className="text-muted-foreground text-sm">Contributors submit voice, image, or text data via mobile.</p>
                </div>
              </div>
              <div className="flex gap-4">
                <div className="flex-none w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-bold">3</div>
                <div>
                  <p className="font-bold">AI Validates</p>
                  <p className="text-muted-foreground text-sm">Our AI layer checks quality and relevance instantly.</p>
                </div>
              </div>
              <div className="flex gap-4">
                <div className="flex-none w-8 h-8 rounded-full bg-primary text-primary-foreground flex items-center justify-center font-bold">4</div>
                <div>
                  <p className="font-bold">Paid Instantly</p>
                  <p className="text-muted-foreground text-sm">Smart contract releases funds to the contributor&apos;s wallet.</p>
                </div>
              </div>
            </div>
          </div>
          <div className="bg-background rounded-2xl p-6 border shadow-xl">
            <div className="space-y-4">
              <div className="flex justify-between items-center border-b pb-4">
                <span className="font-bold">Sample Task</span>
                <Badge>Voice</Badge>
              </div>
              <p className="text-sm">&quot;Record yourself saying: &apos;The quick brown fox jumps over the lazy dog&apos; in your native accent.&quot;</p>
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>Reward: 0.50 cUSD</span>
                <span>Time: ~30s</span>
              </div>
              <Button className="w-full">Try Demo Task</Button>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
