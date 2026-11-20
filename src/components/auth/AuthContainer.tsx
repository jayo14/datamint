import React from 'react'

interface AuthContainerProps {
  children: React.ReactNode
  badgeText?: string
  badgeIcon?: string
  title: string
  subtitle: string
  floatingTags?: Array<{
    text: string
    icon: string
    className?: string
  }>
}

export function AuthContainer({
  children,
  badgeText = 'Decentralized AI Data Marketplace',
  badgeIcon = 'shield_lock',
  title,
  subtitle,
  floatingTags = [],
}: AuthContainerProps) {
  return (
    <div
      className="pg min-h-screen flex flex-col justify-between selection:bg-[#74E3B6] selection:text-[#0D1F18]"
      data-element-type="section"
      data-label="Auth Page Container"
    >
      <div className="w-full flex-1 flex flex-col justify-center items-center px-4 py-8 md:py-12 relative overflow-hidden">
        {/* Ambient Decorative Glowing Coins / Orbs */}
        <div
          className="coin w-32 h-32 -top-6 -left-10 md:left-12 pointer-events-none opacity-40 bg-[#74E3B6]"
          aria-hidden="true"
        />
        <div
          className="coin w-40 h-40 -bottom-8 -right-8 md:right-16 pointer-events-none opacity-30 bg-[#FFE08A]"
          style={{ animationDelay: '-3.5s' }}
          aria-hidden="true"
        />

        {/* Floating Decorative Tags (visible on large screens) */}
        {floatingTags.map((tag, idx) => (
          <div
            key={idx}
            className={`tg hidden xl:flex ${tag.className || ''}`}
            aria-hidden="true"
          >
            <span className="ms text-lg text-[#0B9E6B]">{tag.icon}</span>
            <span>{tag.text}</span>
          </div>
        ))}

        {/* Main Content Box */}
        <div className="w-full max-w-[580px] z-10 mx-auto">
          {/* Header Section */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center gap-2.5 px-4 py-1.5 rounded-full bg-white border border-[#BFE3D2] shadow-sm mb-4">
              <span className="w-2.5 h-2.5 rounded-full bg-[#74E3B6] animate-pulse" />
              <span className="ms text-base text-[#0D1F18]">{badgeIcon}</span>
              <span className="text-xs font-semibold uppercase tracking-wider text-[#3F5F52]">
                {badgeText}
              </span>
            </div>

            <h1 className="h2 !text-3xl md:!text-4xl !font-medium tracking-tight text-[#0D1F18] mb-3">
              {title}
            </h1>
            <p className="text-[#3F5F52] text-base md:text-lg max-w-md mx-auto leading-relaxed">
              {subtitle}
            </p>
          </div>

          {/* Dynamic Card Body */}
          <div className="bg-white/95 backdrop-blur-xl border border-[#BFE3D2]/70 rounded-[36px] md:rounded-[44px] p-6 sm:p-10 shadow-[0_24px_50px_-15px_rgba(15,42,33,0.12)] relative">
            {children}
          </div>
        </div>
      </div>
    </div>
  )
}
