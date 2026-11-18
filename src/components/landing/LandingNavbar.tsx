'use client'

import { useEffect, useRef } from 'react'
import Link from 'next/link'
import { useWeb3 } from '@/hooks/useWeb3'

export function LandingNavbar() {
  const { address, connect, isConnected, isConnecting } = useWeb3()
  const progRef = useRef<HTMLElement>(null)

  useEffect(() => {
    // Fallback scroll progress indicator for browsers without CSS scroll-timeline
    const updateProgress = () => {
      if (!progRef.current) return
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight
      if (maxScroll <= 0) return
      const progress = Math.min(Math.max(window.scrollY / maxScroll, 0), 1)
      progRef.current.style.transform = `scaleX(${progress})`
    }

    window.addEventListener('scroll', updateProgress, { passive: true })
    updateProgress()
    return () => window.removeEventListener('scroll', updateProgress)
  }, [])

  const truncateAddress = (addr: string) => `${addr.slice(0, 6)}...${addr.slice(-4)}`

  return (
    <div className="nav">
      <i ref={progRef} className="prog" aria-hidden="true" />
      <div>
        <Link className="lg" href="/">
          <i>D</i>
          <span>datamint</span>
        </Link>
        <nav className="pill" aria-label="Primary">
          <a href="#how">How it works</a>
          <a href="#escrow">Escrow</a>
          <a href="#data">Datasets</a>
          <a href="#start">Start</a>
        </nav>
        <div style={{ display: 'flex', gap: '10px', pointerEvents: 'none' }}>
          {isConnected ? (
            <button
              type="button"
              className="btn w2"
              style={{ height: '52px', padding: '0 24px', fontSize: '15px' }}
            >
              {truncateAddress(address!)}
            </button>
          ) : (
            <button
              type="button"
              className="btn w2"
              onClick={connect}
              disabled={isConnecting}
              style={{ height: '52px', padding: '0 24px', fontSize: '15px' }}
            >
              {isConnecting ? 'Connecting...' : 'Connect wallet'}
            </button>
          )}
          <Link
            className="btn"
            href="/login"
            style={{ height: '52px', padding: '0 24px', fontSize: '15px' }}
          >
            Sign in
          </Link>
        </div>
      </div>
    </div>
  )
}
