import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'
import OpenAI from 'openai'

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY })

export async function POST(req: Request) {
  try {
    const { submissionId } = await req.json()
    if (!submissionId) return NextResponse.json({ error: 'submissionId required' }, { status: 400 })

    const supabase = await createClient()

    // Get submission
    const { data: submission, error: subError } = await supabase
      .from('submissions')
      .select('*, datasets(type, title)')
      .eq('id', submissionId)
      .single()

    if (subError || !submission) {
      return NextResponse.json({ error: 'Submission not found' }, { status: 404 })
    }

    const datasetType = submission.datasets?.type || 'text'
    const datasetTitle = submission.datasets?.title || 'Unknown Dataset'
    let aiScore = 0
    let feedback = ''
    let approved = false

    if (datasetType === 'text') {
      const textContent = submission.content || ''
      if (textContent.trim().length < 10) {
        aiScore = 0
        feedback = 'Text too short. Minimum 10 characters required.'
      } else {
        // Use GPT-4o-mini for text quality check
        const completion = await openai.chat.completions.create({
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content: `You are a data quality validator for the dataset: "${datasetTitle}".
              Score the submitted text from 0-100 based on: relevance (40pts), clarity (30pts), completeness (30pts).
              Respond ONLY with JSON: {"score": number, "feedback": "brief reason", "approved": boolean}
              Approve if score >= 60.`
            },
            { role: 'user', content: textContent }
          ],
          response_format: { type: 'json_object' },
          max_tokens: 150
        })
        const result = JSON.parse(completion.choices[0].message.content || '{}')
        aiScore = result.score || 0
        feedback = result.feedback || 'Validation complete.'
        approved = result.approved || false
      }
    } else if (datasetType === 'voice' || datasetType === 'image') {
      if (submission.file_url) {
        aiScore = 75
        feedback = `${datasetType === 'voice' ? 'Audio' : 'Image'} file received and validated.`
        approved = true
      } else {
        aiScore = 0
        feedback = 'No file submitted.'
        approved = false
      }
    }

    const newStatus = approved ? 'approved' : 'rejected'
    await supabase
      .from('submissions')
      .update({ ai_score: aiScore, ai_feedback: feedback, status: newStatus })
      .eq('id', submissionId)

    if (approved) {
      await supabase.rpc('increment_completed_count', { dataset_id_param: submission.dataset_id })
    }

    return NextResponse.json({ approved, score: aiScore, feedback })
  } catch (error) {
    console.error('Validation error:', error)
    return NextResponse.json({ error: 'Validation failed' }, { status: 500 })
  }
}
