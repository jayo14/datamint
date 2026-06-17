import { createClient } from '@/lib/supabase/server'
import { NextResponse, type NextRequest } from 'next/server'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ datasetId: string }> }
) {
  const { datasetId } = await params
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { data: dataset } = await supabase
    .from('datasets')
    .select('*')
    .eq('id', datasetId)
    .eq('creator_id', user.id)
    .single()

  if (!dataset) return NextResponse.json({ error: 'Dataset not found or unauthorized' }, { status: 404 })

  const { data: submissions } = await supabase
    .from('submissions')
    .select('id, content, file_url, ai_score, ai_feedback, status, created_at')
    .eq('dataset_id', datasetId)
    .eq('status', 'approved')
    .order('created_at', { ascending: true })

  const exportData = {
    metadata: {
      dataset_id: dataset.id,
      title: dataset.title,
      type: dataset.type,
      total_submissions: submissions?.length || 0,
      exported_at: new Date().toISOString(),
      reward_per_task_cusd: dataset.reward_per_task
    },
    submissions: submissions || []
  }

  return new NextResponse(JSON.stringify(exportData, null, 2), {
    headers: {
      'Content-Type': 'application/json',
      'Content-Disposition': `attachment; filename="datamint-${dataset.id}-export.json"`
    }
  })
}
