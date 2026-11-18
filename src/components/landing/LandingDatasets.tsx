export function LandingDatasets() {
  return (
    <section id="data" className="sec" style={{ paddingTop: '20px' }}>
      <div className="w rv" style={{ textAlign: 'center' }}>
        <h2 className="h2">
          Datasets your models will actually thank you for.
        </h2>
      </div>

      <div className="w" style={{ marginTop: '90px' }}>
        <span className="lab">
          <b />
          Your data
        </span>
      </div>

      <div className="rail">
        {/* Card 1: CSV or JSON export */}
        <div className="cd rv" style={{ background: '#fff' }}>
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
              <div
                style={{
                  height: '46px',
                  borderRadius: '16px',
                  background: '#fff',
                }}
              />
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

        {/* Card 3: Global crowd globe */}
        <div className="cd rv" style={{ background: '#D9F3FF' }}>
          <h3>A crowd as global as your users.</h3>
          <div className="art">
            <div
              style={{
                position: 'absolute',
                left: '50%',
                marginLeft: '-110px',
                bottom: '40px',
                width: '220px',
                height: '220px',
                borderRadius: '50%',
                background:
                  'radial-gradient(circle at 35% 30%, #fff, #7FC8E8)',
                boxShadow: 'inset -20px -20px 40px rgba(13, 31, 24, 0.15)',
              }}
            />
            <span className="tg" style={{ left: '30px', bottom: '190px' }}>
              Lagos
            </span>
            <span
              className="tg"
              style={{
                right: '26px',
                bottom: '110px',
                animationDelay: '-3s',
              }}
            >
              Nairobi
            </span>
          </div>
        </div>

        {/* Card 4: Voice, image, text pipeline */}
        <div className="cd rv" style={{ background: 'var(--dk)', color: '#fff' }}>
          <h3>Voice, image and text in one pipeline.</h3>
          <div className="art">
            <span
              className="tg"
              style={{
                left: '30px',
                bottom: '200px',
                background: 'var(--m)',
              }}
            >
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
              Text
            </span>
          </div>
        </div>
      </div>
    </section>
  )
}
