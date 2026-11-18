'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useWeb3 } from '@/hooks/useWeb3'

export function LandingFooter() {
  const { connect, isConnected, isConnecting, address } = useWeb3()
  const [email, setEmail] = useState('')
  const [subscribed, setSubscribed] = useState(false)

  const handleSubscribe = (e: React.FormEvent) => {
    e.preventDefault()
    if (!email || !email.includes('@')) return
    setSubscribed(true)
  }

  const truncateAddress = (addr: string) => `${addr.slice(0, 6)}...${addr.slice(-4)}`

  return (
    <section
      id="start"
      style={{
        background: 'var(--m)',
        borderRadius: '56px 56px 0 0',
        padding: '150px 0 28px',
        textAlign: 'center',
      }}
    >
      <div className="w rv">
        <p
          style={{
            font: '500 18px var(--font-inter, Inter)',
            color: '#14382B',
            margin: 0,
          }}
        >
          Built for builders and contributors worldwide.
        </p>
        <h2
          className="h2"
          style={{
            fontSize: 'clamp(48px, 8vw, 112px)',
            marginTop: '22px',
          }}
        >
          Get started. Mint your first dataset.
        </h2>
        <div style={{ marginTop: '44px' }}>
          <Link
            className="btn"
            href="/login"
            style={{
              background: '#fff',
              height: '64px',
              padding: '0 38px',
              fontSize: '18px',
            }}
          >
            Start building
          </Link>
        </div>
      </div>

      <div className="w" style={{ marginTop: '150px', textAlign: 'left' }}>
        <footer className="ft rv">
          <div>
            <Link className="lg" href="/" style={{ margin: 0 }}>
              <i>D</i>
              <span>datamint</span>
            </Link>
            <form onSubmit={handleSubscribe}>
              <label className="mail" style={{ marginTop: '28px' }}>
                <input
                  type="email"
                  placeholder={subscribed ? 'Thank you for subscribing!' : 'Enter your email'}
                  aria-label="Email address"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={subscribed}
                  required
                />
                <button
                  type="submit"
                  className="btn"
                  style={{ height: '44px', padding: '0 20px' }}
                  disabled={subscribed}
                >
                  {subscribed ? 'Joined' : 'Sign up'}
                </button>
              </label>
            </form>
          </div>

          <div>
            <b>Product</b>
            <a href="#how">How it works</a>
            <a href="#escrow">Escrow</a>
            <a href="#data">Datasets</a>
          </div>

          <div>
            <b>Contribute</b>
            <a href="#how">MiniPay</a>
            <Link href="/tasks">Demo task</Link>
            <a href="mailto:support@datamint.io">Support</a>
          </div>

          <div>
            <b>Account</b>
            {isConnected ? (
              <button
                type="button"
                onClick={connect}
                style={{
                  background: 'none',
                  border: 'none',
                  padding: 0,
                  cursor: 'pointer',
                  textAlign: 'left',
                }}
              >
                <span>{truncateAddress(address!)}</span>
              </button>
            ) : (
              <button
                type="button"
                onClick={connect}
                disabled={isConnecting}
                style={{
                  background: 'none',
                  border: 'none',
                  padding: 0,
                  cursor: 'pointer',
                  textAlign: 'left',
                }}
              >
                <span>{isConnecting ? 'Connecting...' : 'Connect wallet'}</span>
              </button>
            )}
            <Link href="/login">Sign in</Link>
            <Link href="/login">Terms</Link>
          </div>
        </footer>

        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            padding: '22px 8px 0',
            fontSize: '14px',
            color: '#14382B',
          }}
        >
          <span>© 2026 DataMint</span>
          <span style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
            <i className="live" />
            Operational
          </span>
        </div>
      </div>
    </section>
  )
}
