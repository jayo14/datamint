export function LandingEscrow() {
  return (
    <section id="escrow" className="dkb sec pn">
      <div className="stk">
        <div className="w rv" style={{ textAlign: 'center' }}>
          <h2 className="h2" style={{ color: '#fff' }}>
            Money that moves <i className="mk" /> when the data is good.
          </h2>
        </div>
        <div
          className="w"
          style={{
            marginTop: '90px',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <span className="lab">
            <b />
            On-chain escrow
          </span>
          <span className="arr" aria-hidden="true">
            <i className="ms">chevron_left</i>
            <i className="ms">chevron_right</i>
          </span>
        </div>
        <div className="rail">
          {/* Card 1: One smart contract */}
          <div className="cd rv gl">
            <span className="ic">
              <span className="ms" aria-hidden="true">shield_lock</span>
            </span>
            <h3>One smart contract. Zero trust required.</h3>
            <div className="art">
              <div
                style={{
                  position: 'absolute',
                  left: '50%',
                  bottom: '70px',
                  width: '170px',
                  height: '170px',
                  marginLeft: '-85px',
                  borderRadius: '50%',
                  border: '2px dashed rgba(116,227,182,.75)',
                  animation: 'sp 18s linear infinite',
                }}
              />
              <div
                style={{
                  position: 'absolute',
                  left: '50%',
                  bottom: '105px',
                  width: '100px',
                  height: '100px',
                  marginLeft: '-50px',
                  borderRadius: '30px',
                  background: 'var(--m)',
                  display: 'grid',
                  placeItems: 'center',
                  color: 'var(--ink)',
                }}
              >
                <i
                  className="lgo celo"
                  role="img"
                  aria-label="Celo"
                  style={{ fontSize: '52px' }}
                />
              </div>
            </div>
          </div>

          {/* Card 2: Payouts in seconds */}
          <div className="cd rv gl">
            <span className="ic">
              <span className="ms" aria-hidden="true">bolt</span>
            </span>
            <h3>Payouts in seconds, not billing cycles.</h3>
            <div className="art">
              <div
                className="bf"
                style={{
                  position: 'absolute',
                  left: '32px',
                  bottom: '60px',
                  font: '600 110px/1 var(--bf)',
                  letterSpacing: '-.06em',
                  color: 'var(--m)',
                }}
              >
                0.50
              </div>
              <div
                style={{
                  position: 'absolute',
                  left: '36px',
                  bottom: '34px',
                  font: '500 16px Inter',
                  color: '#CFE6DC',
                }}
              >
                cUSD per 30-second task
              </div>
            </div>
          </div>

          {/* Card 3: MiniPay */}
          <div className="cd rv gl">
            <span className="ic">
              <span className="ms" aria-hidden="true">smartphone</span>
            </span>
            <h3>Made for MiniPay and mobile-first contributors.</h3>
            <div className="art">
              <div
                style={{
                  position: 'absolute',
                  left: '50%',
                  marginLeft: '-100px',
                  bottom: '-60px',
                  width: '200px',
                  height: '290px',
                  borderRadius: '36px',
                  background: 'var(--ink)',
                  padding: '14px',
                }}
              >
                <div
                  style={{
                    height: '100%',
                    borderRadius: '26px',
                    background: 'var(--bg)',
                    padding: '20px 16px',
                    textAlign: 'center',
                  }}
                >
                  <div style={{ font: '600 15px var(--bf)' }}>Record a phrase</div>
                  <div style={{ marginTop: '22px', height: '50px' }}>
                    <span className="bar" style={{ height: '20px' }} />
                    <span className="bar" style={{ height: '40px', animationDelay: '.2s' }} />
                    <span className="bar" style={{ height: '28px', animationDelay: '.4s' }} />
                    <span className="bar" style={{ height: '46px', animationDelay: '.1s' }} />
                    <span className="bar" style={{ height: '24px', animationDelay: '.3s' }} />
                  </div>
                  <div
                    style={{
                      margin: '14px auto 0',
                      width: '56px',
                      height: '56px',
                      borderRadius: '50%',
                      background: '#FF6B5B',
                    }}
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Card 4: Nothing released until validation passes */}
          <div className="cd rv gl">
            <span className="ic">
              <span className="ms" aria-hidden="true">verified_user</span>
            </span>
            <h3>Nothing is released until validation passes.</h3>
            <div className="art">
              <div
                style={{
                  position: 'absolute',
                  left: '30px',
                  right: '30px',
                  bottom: '60px',
                  display: 'grid',
                  gap: '12px',
                }}
              >
                <div
                  className="glass"
                  style={{
                    padding: '16px 20px',
                    color: 'var(--ink)',
                    font: '600 16px var(--bf)',
                  }}
                >
                  Funded
                </div>
                <div
                  className="glass"
                  style={{
                    padding: '16px 20px',
                    color: 'var(--ink)',
                    font: '600 16px var(--bf)',
                  }}
                >
                  Submitted
                </div>
                <div
                  style={{
                    padding: '16px 20px',
                    borderRadius: '22px',
                    background: 'var(--m)',
                    color: 'var(--ink)',
                    font: '600 16px var(--bf)',
                  }}
                >
                  Released
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
