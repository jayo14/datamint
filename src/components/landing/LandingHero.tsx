import Link from 'next/link'
import type { CSSProperties } from 'react'

export function LandingHero() {
  return (
    <header className="hero">
      <div
        className="coin par"
        style={{ width: '130px', height: '130px', background: '#74E3B6', left: '8%', top: '30%' }}
      >
        $
      </div>
      <div
        className="coin par"
        style={{
          width: '70px',
          height: '70px',
          background: '#FFE08A',
          left: '20%',
          top: '72%',
          fontSize: '16px',
        }}
      >
        0.50
      </div>
      <div
        className="coin par"
        style={{
          width: '96px',
          height: '96px',
          background: '#FFB89A',
          right: '10%',
          top: '26%',
          opacity: 0.9,
        }}
      />
      <div
        className="coin par"
        style={{
          width: '150px',
          height: '150px',
          background: '#2FBF8A',
          right: '7%',
          top: '62%',
          opacity: 0.8,
        }}
      >
        cUSD
      </div>
      <div
        className="coin par"
        style={{
          width: '44px',
          height: '44px',
          background: '#fff',
          left: '38%',
          top: '84%',
          opacity: 0.7,
        }}
      />
      <div className="coin3 par" style={{ right: '-50px', top: '60px' }}>
        <b>D</b>
      </div>
      <div className="stk3 par" style={{ left: '-40px', bottom: '70px' }}>
        <span className="ms" aria-hidden="true">graphic_eq</span>
      </div>
      <i className="spk" style={{ left: '13%', top: '36%' }} />
      <i className="spk" style={{ right: '31%', top: '15%', animationDelay: '-1s' }} />
      <i className="spk" style={{ left: '31%', bottom: '13%', animationDelay: '-2s' }} />
      <i
        className="spk"
        style={{ right: '12%', bottom: '22%', animationDelay: '-1.5s', width: '20px', height: '20px' }}
      />
      <div
        style={{
          position: 'absolute',
          width: '700px',
          height: '700px',
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(116,227,182,0.35), transparent 65%)',
          top: '-320px',
          left: '50%',
          marginLeft: '-350px',
        }}
      />
      <div className="ctn" style={{ position: 'relative', maxWidth: '980px' }}>
        <span style={{ font: '500 20px Inter', color: '#B7D6C9' }}>Human data, minted on Celo</span>
        <h1 className="h1">
          <span className="ln">
            <span style={{ '--d': 1 } as CSSProperties}>Where human</span>
          </span>
          <span className="ln">
            <span style={{ '--d': 2 } as CSSProperties}>knowledge</span>
          </span>
          <span className="ln">
            <span style={{ '--d': 3 } as CSSProperties}>
              <em>gets paid.</em>
            </span>
          </span>
        </h1>
        <p
          style={{
            font: '400 20px/1.6 Inter',
            color: '#B7D6C9',
            maxWidth: '620px',
            margin: '28px auto 0',
          }}
        >
          Collect voice, image and text data for your AI models. Validated by AI, released from escrow, paid out in seconds.
        </p>
        <div
          style={{
            display: 'flex',
            gap: '14px',
            justifyContent: 'center',
            marginTop: '44px',
            flexWrap: 'wrap',
          }}
        >
          <a
            className="btn"
            href="#start"
            style={{ height: '64px', padding: '0 38px', fontSize: '18px' }}
          >
            Start building
            <span className="ms" aria-hidden="true">arrow_forward</span>
          </a>
          <a
            className="btn g"
            href="#try"
            style={{ height: '64px', padding: '0 34px', fontSize: '18px' }}
          >
            <span className="ms" aria-hidden="true">play_circle</span>
            Try a demo task
          </a>
        </div>
      </div>
    </header>
  )
}
