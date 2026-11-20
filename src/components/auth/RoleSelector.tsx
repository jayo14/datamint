import React from 'react'

export type UserRole = 'contributor' | 'creator'

interface RoleSelectorProps {
  role: UserRole
  onRoleChange: (role: UserRole) => void
  showSubtitles?: boolean
}

export function RoleSelector({ role, onRoleChange, showSubtitles = false }: RoleSelectorProps) {
  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <label className="text-xs font-bold uppercase tracking-wider text-[#3F5F52]">
          Select Your Role
        </label>
        <span className="text-xs text-[#0B9E6B] font-medium flex items-center gap-1">
          <span className="w-1.5 h-1.5 rounded-full bg-[#0B9E6B]" />
          {role === 'contributor' ? 'Earn micro-rewards' : 'Request AI datasets'}
        </span>
      </div>

      <div
        className="grid grid-cols-2 p-1.5 bg-[#EAFBF3] rounded-2xl border border-[#BFE3D2]/70 gap-1.5"
        role="radiogroup"
        aria-label="Account Role Selection"
      >
        <button
          type="button"
          role="radio"
          aria-checked={role === 'contributor'}
          onClick={() => onRoleChange('contributor')}
          className={`flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-medium text-sm transition-all duration-200 ${
            role === 'contributor'
              ? 'bg-white shadow-[0_4px_12px_rgba(15,42,33,0.08)] text-[#0D1F18] font-bold border border-[#BFE3D2]/60'
              : 'text-[#3F5F52] hover:text-[#0D1F18] hover:bg-white/40'
          }`}
        >
          <span
            className={`ms text-xl transition-colors ${
              role === 'contributor' ? 'text-[#0B9E6B]' : 'text-[#3F5F52]'
            }`}
            aria-hidden="true"
          >
            paid
          </span>
          <span>Contributor</span>
        </button>

        <button
          type="button"
          role="radio"
          aria-checked={role === 'creator'}
          onClick={() => onRoleChange('creator')}
          className={`flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-medium text-sm transition-all duration-200 ${
            role === 'creator'
              ? 'bg-white shadow-[0_4px_12px_rgba(15,42,33,0.08)] text-[#0D1F18] font-bold border border-[#BFE3D2]/60'
              : 'text-[#3F5F52] hover:text-[#0D1F18] hover:bg-white/40'
          }`}
        >
          <span
            className={`ms text-xl transition-colors ${
              role === 'creator' ? 'text-[#0B9E6B]' : 'text-[#3F5F52]'
            }`}
            aria-hidden="true"
          >
            psychology
          </span>
          <span>Creator</span>
        </button>
      </div>

      {showSubtitles && (
        <p className="text-xs text-[#3F5F52] text-center pt-0.5">
          {role === 'contributor'
            ? 'Complete speech, audio & image tasks for instant Celo cUSD payouts.'
            : 'Deploy smart escrow contracts and crowd-source verified training data.'}
        </p>
      )}
    </div>
  )
}
