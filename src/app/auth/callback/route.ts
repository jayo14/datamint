import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import { cookies } from 'next/headers'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next') ?? '/'

  if (code) {
    const supabase = await createClient()
    const { error, data } = await supabase.auth.exchangeCodeForSession(code)

    if (!error && data.user) {
      const cookieStore = await cookies()
      const intendedRole = cookieStore.get('datamint_intended_role')?.value
      const walletAddress = cookieStore.get('datamint_wallet_address')?.value

      const { data: profile } = await supabase.from('users').select('*').eq('id', data.user.id).single()

      if (!profile) {
        await supabase.from('users').insert({
          id: data.user.id,
          role: (intendedRole as 'creator' | 'contributor') || 'contributor',
          wallet_address: walletAddress || null
        })
      }

      const finalNext = next === '/' ? (intendedRole === 'creator' || profile?.role === 'creator' ? '/dashboard' : '/tasks') : next
      return NextResponse.redirect(`${origin}${finalNext}`)
    }
  }
  return NextResponse.redirect(`${origin}/auth/auth-code-error`)
}
