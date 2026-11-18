export function LandingMarquee() {
  const items = [
    'Voice',
    'Image',
    'Text',
    'Celo',
    'cUSD',
    'MiniPay',
    'GPT-4o',
    'Smart escrow',
  ]

  // We repeat the sequence twice to enable a seamless -50% CSS loop
  const tickerItems = [...items, ...items]

  return (
    <div className="mqw" aria-hidden="true">
      <div className="mq">
        {tickerItems.map((item, index) => (
          <span key={index}>{item}</span>
        ))}
      </div>
    </div>
  )
}
