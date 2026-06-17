import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  try {
    const supabase = await createClient()
    const { data: { user } } = await supabase.auth.getUser()

    if (!user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const formData = await req.formData()
    const file = formData.get('file') as File | null
    const content = formData.get('content') as string | null
    const datasetId = formData.get('datasetId') as string

    if (!datasetId) {
      return NextResponse.json({ error: 'datasetId is required' }, { status: 400 })
    }

    let fileUrl = ''
    if (file) {
      const fileName = `${user.id}/${Date.now()}-${file.name}`
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('submissions')
        .upload(fileName, file)

      if (uploadError) {
        return NextResponse.json({ error: 'Upload failed: ' + uploadError.message }, { status: 500 })
      }
      fileUrl = uploadData.path
    }

    const { data: submission, error: insertError } = await supabase
      .from('submissions')
      .insert({
        dataset_id: parseInt(datasetId),
        user_id: user.id,
        file_url: fileUrl || null,
        content: content || null,
        status: 'pending'
      })
      .select('id')
      .single()

    if (insertError) {
      return NextResponse.json({ error: 'Database insert failed: ' + insertError.message }, { status: 500 })
    }

    const validateUrl = new URL('/api/validate', req.url).toString()
    fetch(validateUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ submissionId: submission.id })
    }).catch(console.error)

    return NextResponse.json({ success: true, submissionId: submission.id })
  } catch (error: any) {
    console.error('Upload error:', error)
    return NextResponse.json({ error: 'Internal server error: ' + error.message }, { status: 500 })
  }
}
