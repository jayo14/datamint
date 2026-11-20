export function LandingDatasets() {
  return (
    <section id="data" className="sec pn">
      <div className="stk">
        <div className="w rv" style={{ textAlign: 'center' }}>
          <h2 className="h2">
            Datasets your models will actually thank you for <i className="mk" />
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
            Your data
          </span>
          <span className="arr" aria-hidden="true">
            <i className="ms">chevron_left</i>
            <i className="ms">chevron_right</i>
          </span>
        </div>
        <div className="rail">
          {/* Card 1: Export clean CSV or JSON */}
          <div className="cd rv" style={{ background: '#fff' }}>
            <span className="ic">
              <span className="ms" aria-hidden="true">download</span>
            </span>
            <h3>Export clean CSV or JSON. Your call.</h3>
            <div className="art">
              <div
                style={{
                  position: 'absolute',
                  left: '32px',
                  right: '32px',
                  bottom: '50px',
                  background: 'var(--dk)',
                  borderRadius: '22px',
                  padding: '22px',
                  color: 'var(--m)',
                  font: '500 15px/1.7 ui-monospace, monospace',
                }}
              >
                {'{ "type": "voice",'}
                <br />
                &nbsp;&nbsp;{'"accent": "yoruba",'}
                <br />
                &nbsp;&nbsp;{'"valid": true }'}
              </div>
            </div>
          </div>

          {/* Card 2: Quality you can audit */}
          <div className="cd rv" style={{ background: '#FFE3D4' }}>
            <span className="ic">
              <span className="ms" aria-hidden="true">fact_check</span>
            </span>
            <h3>Quality you can audit, one record at a time.</h3>
            <div className="art">
              <div
                style={{
                  position: 'absolute',
                  left: '32px',
                  right: '32px',
                  bottom: '50px',
                  display: 'grid',
                  gap: '10px',
                }}
              >
                <div style={{ height: '46px', borderRadius: '16px', background: '#fff' }} />
                <div
                  style={{
                    height: '46px',
                    borderRadius: '16px',
                    background: '#fff',
                    width: '82%',
                  }}
                />
                <div
                  style={{
                    height: '46px',
                    borderRadius: '16px',
                    background: 'var(--ink)',
                    width: '64%',
                  }}
                />
              </div>
            </div>
          </div>

          {/* Card 3: Global crowd */}
          <div className="cd rv" style={{ background: '#D9F3FF' }}>
            <span className="ic">
              <span className="ms" aria-hidden="true">groups</span>
            </span>
            <h3>A crowd as global as your users.</h3>
            <div className="art">
              <div
                className="globe"
                style={{
                  position: 'absolute',
                  left: '50%',
                  marginLeft: '-110px',
                  bottom: '40px',
                  width: '220px',
                  height: '220px',
                  borderRadius: '50%',
                  background: 'radial-gradient(circle at 35% 30%, #fff, #7FC8E8)',
                  boxShadow: 'inset -20px -20px 40px rgba(13,31,24,.15)',
                }}
              />
              <span className="tg" style={{ left: '30px', bottom: '190px' }}>
                <span className="ms" aria-hidden="true">location_on</span>
                Lagos
              </span>
              <span
                className="tg"
                style={{ right: '26px', bottom: '110px', animationDelay: '-3s' }}
              >
                <span className="ms" aria-hidden="true">location_on</span>
                Nairobi
              </span>
            </div>
          </div>

          {/* Card 4: Multimodal pipeline */}
          <div className="cd rv" style={{ background: 'var(--dk)', color: '#fff' }}>
            <span className="ic">
              <span className="ms" aria-hidden="true">hub</span>
            </span>
            <h3>Voice, image and text in one pipeline.</h3>
            <div className="art">
              <span
                className="tg"
                style={{ left: '30px', bottom: '200px', background: 'var(--m)' }}
              >
                <span className="ms" aria-hidden="true">mic</span>
                Voice
              </span>
              <span
                className="tg"
                style={{
                  left: '120px',
                  bottom: '120px',
                  animationDelay: '-2s',
                  background: '#FFE08A',
                }}
              >
                <span className="ms" aria-hidden="true">image</span>
                Image
              </span>
              <span
                className="tg"
                style={{
                  left: '50px',
                  bottom: '40px',
                  animationDelay: '-4s',
                  background: '#FFB89A',
                }}
              >
                <span className="ms" aria-hidden="true">text_fields</span>
                Text
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
