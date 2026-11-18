'use client'

import { useEffect, useRef } from 'react'
import type { CSSProperties } from 'react'

export function LandingStatement() {
  const sectionRef = useRef<HTMLElement>(null)

  useEffect(() => {
    // If CSS animation-timeline is supported, let the native CSS do its magic
    if (typeof CSS !== 'undefined' && CSS.supports && CSS.supports('animation-timeline', 'view()')) {
      return
    }

    // Fallback word reveal on scroll for other browsers
    const words = sectionRef.current?.querySelectorAll<HTMLElement>('.wd')
    if (!words || words.length === 0) return

    const handleScroll = () => {
      if (!sectionRef.current) return
      const rect = sectionRef.current.getBoundingClientRect()
      const windowHeight = window.innerHeight

      // Calculate progress of section through the viewport
      const totalDist = windowHeight + rect.height
      const currentPos = windowHeight - rect.top
      const progress = Math.min(Math.max(currentPos / totalDist, 0), 1)

      words.forEach((el, index) => {
        const threshold = 0.2 + (index / words.length) * 0.4
        if (progress >= threshold) {
          el.style.opacity = '1'
        } else {
          el.style.opacity = '0.18'
        }
      })
    }

    window.addEventListener('scroll', handleScroll, { passive: true })
    handleScroll()
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const words = [
    { text: 'Real', i: 0 },
    { text: 'people.', i: 1 },
    { text: 'Real', i: 2 },
    { text: 'data.', i: 3 },
    { text: 'Verified', i: 4 },
    { text: 'on-chain,', i: 5 },
    { text: 'and', i: 6 },
    { text: 'paid', i: 7 },
    { text: 'before', i: 8 },
    { text: 'they', i: 9 },
    { text: 'close', i: 10 },
    { text: 'the', i: 11 },
    { text: 'app.', i: 12 },
  ]

  return (
    <section
      ref={sectionRef}
      className="sec"
      style={{ background: 'var(--bg)', padding: '200px 0' }}
    >
      <div className="w">
        <p className="st">
          {words.map((item) => (
            <span
              key={item.i}
              className="wd"
              style={{ '--i': item.i } as CSSProperties}
            >
              {item.text}
            </span>
          ))}
        </p>
      </div>
    </section>
  )
}
