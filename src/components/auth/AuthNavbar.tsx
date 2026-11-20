import Link from 'next/link'

interface AuthNavbarProps {
  showBackHome?: boolean
  currentStepBadge?: string
}

export function AuthNavbar({ showBackHome = true, currentStepBadge }: AuthNavbarProps) {
  return (
    <header className="nav" data-element-type="container" data-label="Auth Navigation Bar">
      <div>
        <Link href="/" className="lg" data-element-type="link" data-label="DataMint Logo">
          <i>⌘</i>
          <span>DataMint</span>
        </Link>

        <div className="pill hidden sm:flex items-center gap-2.5 px-4 py-2 border border-[#BFE3D2]/60">
          <span className="live" aria-hidden="true" />
          <span className="text-xs font-semibold tracking-wider uppercase text-[#3F5F52]">
            {currentStepBadge || 'Celo L2 • Escrow Ready'}
          </span>
        </div>

        {showBackHome && (
          <Link
            href="/"
            className="btn w2 text-sm !h-11 !px-5 flex items-center gap-1.5 font-medium transition-all"
            data-element-type="button"
            data-label="Back to Home Button"
          >
            <span className="ms text-lg" aria-hidden="true">arrow_back</span>
            <span>Home</span>
          </Link>
        )}
      </div>
    </header>
  )
}
