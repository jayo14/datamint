'use client'

import { useState } from 'react'
import type { CSSProperties } from 'react'

export function LandingDemo() {
  const [isChecked, setIsChecked] = useState(false)

  const handleToggle = () => {
    setIsChecked((prev) => !prev)
  }

  return (
    <section id="try" className="sec" style={{ padding: '10px 0 150px' }}>
      <div
        className="w rv"
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
          gap: '64px',
          alignItems: 'center',
        }}
      >
        <div>
          <span className="lab">
            <b />
            Try it
          </span>
          <h2
            className="h2"
            style={{
              textAlign: 'left',
              margin: '24px 0 0',
              fontSize: 'clamp(40px, 5vw, 68px)',
            }}
          >
            Say it once. Get paid in seconds.
          </h2>
          <p
            style={{
              font: '400 19px/1.65 Inter',
              color: 'var(--tx)',
              margin: '24px 0 0',
              maxWidth: '460px',
            }}
          >
            Hit record on the sample task and watch the whole loop: capture, GPT-4o validation, escrow release.
          </p>
        </div>

        <div style={{ position: 'relative' }}>
          <input
            className="sr"
            type="checkbox"
            id="rec"
            aria-label="Run the demo"
            checked={isChecked}
            onChange={handleToggle}
          />
          <div className="dm glass">
            <div className="toast">
              <span className="ms" aria-hidden="true" style={{ color: 'var(--m)' }}>
                check_circle
              </span>
              +0.50 cUSD
            </div>
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <b
                className="bf"
                style={{
                  font: '600 22px var(--bf)',
                  display: 'flex',
                  gap: '10px',
                  alignItems: 'center',
                }}
              >
                <span className="ms" aria-hidden="true">
                  mic
                </span>
                Sample Task
              </b>
              <span
                style={{
                  background: 'var(--m)',
                  borderRadius: '999px',
                  padding: '6px 14px',
                  font: '600 12px Inter',
                  letterSpacing: '.12em',
                }}
              >
                VOICE
              </span>
            </div>
            <p style={{ fontStyle: 'italic', lineHeight: 1.6, margin: '22px 0 0' }}>
              “Record yourself saying: ‘The quick brown fox jumps over the lazy dog’ in your native accent.”
            </p>
            <div className="bars" aria-hidden="true">
              <i className="b2" style={{ '--k': 0, '--h': 3 } as CSSProperties} />
              <i className="b2" style={{ '--k': 1, '--h': 5 } as CSSProperties} />
              <i className="b2" style={{ '--k': 2, '--h': 4 } as CSSProperties} />
              <i className="b2" style={{ '--k': 3, '--h': 8 } as CSSProperties} />
              <i className="b2" style={{ '--k': 4, '--h': 6 } as CSSProperties} />
              <i className="b2" style={{ '--k': 5, '--h': 9 } as CSSProperties} />
              <i className="b2" style={{ '--k': 6, '--h': 5 } as CSSProperties} />
              <i className="b2" style={{ '--k': 7, '--h': 10 } as CSSProperties} />
              <i className="b2" style={{ '--k': 8, '--h': 6 } as CSSProperties} />
              <i className="b2" style={{ '--k': 9, '--h': 8 } as CSSProperties} />
              <i className="b2" style={{ '--k': 10, '--h': 4 } as CSSProperties} />
              <i className="b2" style={{ '--k': 11, '--h': 7 } as CSSProperties} />
              <i className="b2" style={{ '--k': 12, '--h': 3 } as CSSProperties} />
              <i className="b2" style={{ '--k': 13, '--h': 5 } as CSSProperties} />
            </div>
            <div className="trk">
              <div className="pf" />
            </div>
            <div className="stt" aria-live="polite">
              <span className="s0">
                <span className="ms" aria-hidden="true">
                  hourglass_empty
                </span>
                Ready when you are
              </span>
              <span className="s1">
                <span className="ms" aria-hidden="true">
                  graphic_eq
                </span>
                Recording your voice…
              </span>
              <span className="s2">
                <i
                  className="lgo oai"
                  role="img"
                  aria-label="OpenAI"
                  style={{ fontSize: '22px' }}
                />
                GPT-4o is validating…
              </span>
              <span className="s3">
                <span className="ms" aria-hidden="true">
                  task_alt
                </span>
                Validated. Paid to your wallet.
              </span>
            </div>
            <label
              htmlFor="rec"
              className="btn rb"
              style={{
                width: '100%',
                justifyContent: 'center',
                height: '60px',
                cursor: 'pointer',
              }}
            >
              <span className="ms" aria-hidden="true">
                mic
              </span>
              <span className="o1">Start recording</span>
              <span className="o2">Run it again</span>
            </label>
          </div>
        </div>
      </div>
    </section>
  )
}
