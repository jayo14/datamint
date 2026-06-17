import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Protected routes list
  const isProtectedRoute = request.nextUrl.pathname.startsWith('/dashboard') ||
                          request.nextUrl.pathname.startsWith('/tasks') ||
                          request.nextUrl.pathname.startsWith('/onboarding')

  if (!user && isProtectedRoute) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  if (user) {
    // If logged in and on login page, redirect to appropriate place
    if (request.nextUrl.pathname.startsWith('/login')) {
        return NextResponse.redirect(new URL('/', request.url))
    }

    const { data: profile } = await supabase
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profile) {
      if (profile.role === 'creator' && request.nextUrl.pathname.startsWith('/tasks')) {
        return NextResponse.redirect(new URL('/dashboard', request.url))
      }
      if (profile.role === 'contributor' && request.nextUrl.pathname.startsWith('/dashboard')) {
        return NextResponse.redirect(new URL('/tasks', request.url))
      }
    } else if (isProtectedRoute && !request.nextUrl.pathname.startsWith('/onboarding')) {
        // Logged in but no profile (onboarding needed)
        return NextResponse.redirect(new URL('/onboarding', request.url))
    }
  }

  return response
}
