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
        <p style={{ font: '500 18px Inter', color: '#14382B', margin: 0 }}>
          Built for the people who teach machines. It’s more than a marketplace.
        </p>
        <h2
          className="h2"
          style={{
            fontSize: 'clamp(48px, 8vw, 112px)',
            marginTop: '22px',
          }}
        >
          Get started.
          <br />
          Mint your first <i className="mk" /> dataset.
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
            <span className="ms" aria-hidden="true">
              rocket_launch
            </span>
            Start building
          </Link>
        </div>
      </div>

      <div className="w" style={{ marginTop: '150px', textAlign: 'left' }}>
        <footer className="ft rv">
          <div>
            <Link className="lg" href="#" style={{ margin: 0 }}>
              <i>D</i>datamint
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
                  style={{ height: '44px', padding: '0 20px', cursor: 'pointer' }}
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
            <a href="#">MiniPay</a>
            <a href="#try">Demo task</a>
            <a href="#">Support</a>
          </div>

          <div>
            <b>Account</b>
            {isConnected ? (
              <a href="#" onClick={(e) => e.preventDefault()}>
                {truncateAddress(address!)}
              </a>
            ) : (
              <a
                href="#"
                onClick={(e) => {
                  e.preventDefault()
                  connect()
                }}
              >
                {isConnecting ? 'Connecting...' : 'Connect wallet'}
              </a>
            )}
            <Link href="/login">Sign in</Link>
            <a href="#">Terms</a>
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
