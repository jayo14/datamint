import type { Metadata } from 'next'
import './landing.css'
import { LandingNavbar } from '@/components/landing/LandingNavbar'
import { LandingHero } from '@/components/landing/LandingHero'
import { LandingMarquee } from '@/components/landing/LandingMarquee'
import { LandingHowItWorks } from '@/components/landing/LandingHowItWorks'
import { LandingEscrow } from '@/components/landing/LandingEscrow'
import { LandingStatement } from '@/components/landing/LandingStatement'
import { LandingDemo } from '@/components/landing/LandingDemo'
import { LandingDatasets } from '@/components/landing/LandingDatasets'
import { LandingFooter } from '@/components/landing/LandingFooter'

export const metadata: Metadata = {
  title: 'DataMint',
  description:
    'Collect voice, image and text data for your AI models. Validated by AI, released from escrow, paid out in seconds.',
}

export default function Home() {
  return (
    <div
      className="pg"
      data-canvas-width="1440"
      data-canvas-height="5600"
      data-document-role="page"
      data-label="DataMint Landing"
    >
      <LandingNavbar />
      <LandingHero />
      <LandingMarquee />
      <LandingHowItWorks />
      <LandingEscrow />
      <LandingStatement />
      <LandingDemo />
      <LandingDatasets />
      <LandingFooter />
    </div>
  )
}

