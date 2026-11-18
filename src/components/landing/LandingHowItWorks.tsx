export function LandingHowItWorks() {
  return (
    <section id="how" className="sec">
      <div className="w rv" style={{ textAlign: 'center' }}>
        <h2 className="h2">A data engine for every builder.</h2>
        <div style={{ marginTop: '30px' }}>
          <a
            className="btn"
            href="#escrow"
            style={{
              height: '48px',
              fontSize: '15px',
              padding: '0 24px',
              background: '#fff',
            }}
          >
            See how it works
          </a>
        </div>
      </div>

      <div className="w" style={{ marginTop: '90px' }}>
        <span className="lab">
          <b />
          How it works
        </span>
      </div>

      <div className="rail">
        {/* Card 1: Fund task */}
        <div className="cd rv" style={{ background: 'var(--m)' }}>
          <h3>Fund a task in one tap. Escrow holds the cUSD.</h3>
          <div className="art">
            <div
              style={{
                position: 'absolute',
                left: '36px',
                right: '36px',
                bottom: '-40px',
                height: '270px',
                background: 'var(--dk)',
                borderRadius: '36px 36px 0 0',
                padding: '26px',
                color: '#fff',
              }}
            >
              <div
                style={{
                  font: '500 14px var(--font-inter, Inter)',
                  color: '#B7D6C9',
                }}
              >
                Escrow funded
              </div>
              <div
                className="bf"
                style={{
                  font: '600 56px var(--bf)',
                  letterSpacing: '-.04em',
                  marginTop: '6px',
                }}
              >
                $500
              </div>
              <div
                style={{
                  marginTop: '14px',
                  height: '10px',
                  borderRadius: '5px',
                  background: 'rgba(255, 255, 255, 0.15)',
                }}
              >
                <div
                  style={{
                    width: '64%',
                    height: '100%',
                    borderRadius: '5px',
                    background: 'var(--m)',
                  }}
                />
              </div>
              <div
                style={{
                  font: '500 14px var(--font-inter, Inter)',
                  color: '#B7D6C9',
                  marginTop: '10px',
                }}
              >
                320 of 500 tasks claimed
              </div>
            </div>
          </div>
        </div>

        {/* Card 2: Contributors */}
        <div className="cd rv" style={{ background: 'var(--dk)', color: '#fff' }}>
          <h3>Contributors join from anywhere on earth.</h3>
          <div className="art">
            <div
              style={{
                position: 'absolute',
                left: '50%',
                bottom: '60px',
                width: '130px',
                height: '130px',
                marginLeft: '-65px',
                borderRadius: '50%',
                background: 'var(--m)',
                display: 'grid',
                placeItems: 'center',
                color: 'var(--ink)',
                font: '600 24px var(--bf)',
              }}
            >
              You
            </div>
            <span className="tg" style={{ left: '24px', bottom: '200px' }}>
              Voice
            </span>
            <span
              className="tg"
              style={{
                right: '30px',
                bottom: '150px',
                animationDelay: '-2s',
              }}
            >
              Image
            </span>
            <span
              className="tg"
              style={{
                left: '70px',
                bottom: '40px',
                animationDelay: '-4s',
              }}
            >
              Text
            </span>
          </div>
        </div>

        {/* Card 3: GPT-4o validation */}
        <div className="cd rv" style={{ background: '#FFF1B8' }}>
          <h3>Every submission checked by GPT-4o in seconds.</h3>
          <div className="art">
            <div
              style={{
                position: 'absolute',
                left: '50%',
                bottom: '50px',
                width: '200px',
                height: '200px',
                marginLeft: '-100px',
                borderRadius: '50%',
                background:
                  'conic-gradient(var(--ink) 0 92%, rgba(13,31,24,.12) 0)',
                display: 'grid',
                placeItems: 'center',
              }}
            >
              <div
                style={{
                  width: '156px',
                  height: '156px',
                  borderRadius: '50%',
                  background: '#FFF1B8',
                  display: 'grid',
                  placeItems: 'center',
                  textAlign: 'center',
                  font: '600 40px var(--bf)',
                  letterSpacing: '-.04em',
                }}
              >
                <span>
                  Pass
                  <br />
                  <span
                    style={{
                      font: '500 14px var(--font-inter, Inter)',
                      letterSpacing: 0,
                    }}
                  >
                    quality + relevance
                  </span>
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Card 4: Approved & Paid */}
        <div className="cd rv" style={{ background: '#FFC9B0' }}>
          <h3>Approved? Paid. Straight to the wallet.</h3>
          <div className="art">
            <div
              className="glass"
              style={{
                position: 'absolute',
                left: '30px',
                right: '30px',
                bottom: '150px',
                padding: '18px 20px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                transform: 'rotate(-3deg)',
              }}
            >
              <b
                className="bf"
                style={{
                  font: '600 18px var(--bf)',
                }}
              >
                Task approved
              </b>
              <span style={{ font: '500 14px var(--font-inter, Inter)' }}>
                now
              </span>
            </div>
            <div
              style={{
                position: 'absolute',
                left: '30px',
                right: '30px',
                bottom: '40px',
                padding: '22px 22px',
                background: 'var(--ink)',
                color: '#fff',
                borderRadius: '24px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                transform: 'rotate(2deg)',
              }}
            >
              <span
                style={{
                  font: '500 15px var(--font-inter, Inter)',
                  color: '#B7D6C9',
                }}
              >
                Received
              </span>
              <b
                className="bf"
                style={{
                  font: '600 32px var(--bf)',
                  color: 'var(--m)',
                }}
              >
                +0.50 cUSD
              </b>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
