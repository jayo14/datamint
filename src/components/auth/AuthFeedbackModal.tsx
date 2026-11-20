'use client'

import React, { useEffect } from 'react'

export type ModalType = 'success' | 'error' | 'wallet'

interface AuthFeedbackModalProps {
  isOpen: boolean
  onClose: () => void
  type: ModalType
  title: string
  message: string
  subMessage?: string
  actionLabel?: string
  onAction?: () => void
}

export function AuthFeedbackModal({
  isOpen,
  onClose,
  type,
  title,
  message,
  subMessage,
  actionLabel = 'Dismiss',
  onAction,
}: AuthFeedbackModalProps) {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose()
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [isOpen, onClose])

  if (!isOpen) return null

  const iconName =
    type === 'success'
      ? 'mark_email_read'
      : type === 'error'
      ? 'error'
      : 'account_balance_wallet'

  const iconBg =
    type === 'success'
      ? 'bg-[#74E3B6]/30 text-[#0B9E6B]'
      : type === 'error'
      ? 'bg-red-100 text-red-600'
      : 'bg-[#74E3B6]/30 text-[#0D1F18]'

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#0F2A21]/60 backdrop-blur-md animate-in fade-in duration-200"
      role="dialog"
      aria-modal="true"
      onClick={onClose}
    >
      <div
        className="w-full max-w-md bg-white border border-[#BFE3D2] rounded-[32px] p-6 sm:p-8 shadow-[0_32px_64px_-16px_rgba(15,42,33,0.3)] space-y-6 text-center animate-in zoom-in-95 duration-200 relative"
        onClick={(e) => e.stopPropagation()}
      >
        <button
          type="button"
          onClick={onClose}
          className="absolute top-5 right-5 w-8 h-8 rounded-full bg-[#EAFBF3] text-[#3F5F52] hover:text-[#0D1F18] flex items-center justify-center text-sm font-bold transition-colors cursor-pointer"
          aria-label="Close dialog"
        >
          ✕
        </button>

        <div className={`w-16 h-16 rounded-full ${iconBg} mx-auto flex items-center justify-center`}>
          <span className="ms text-3xl" aria-hidden="true">
            {iconName}
          </span>
        </div>

        <div className="space-y-2">
          <h3 className="h2 !text-2xl !font-bold text-[#0D1F18]">{title}</h3>
          <p className="text-sm text-[#3F5F52] leading-relaxed">{message}</p>
        </div>

        {subMessage && (
          <div className="p-3.5 rounded-2xl bg-[#EAFBF3] border border-[#BFE3D2]/70 text-xs text-[#3F5F52] text-left leading-relaxed">
            {subMessage}
          </div>
        )}

        <button
          type="button"
          onClick={() => {
            if (onAction) onAction()
            onClose()
          }}
          className="btn w-full !h-12 !rounded-full !flex !items-center !justify-center !gap-2 text-[#0D1F18] font-bold text-sm cursor-pointer shadow-[0_10px_25px_-5px_rgba(116,227,182,0.4)]"
        >
          <span>{actionLabel}</span>
        </button>
      </div>
    </div>
  )
}
