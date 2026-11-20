'use client'

import { useState, useEffect, useCallback, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { api, type Campaign } from '@/lib/api'
import { Button } from '@/components/ui/button'
import { Card, CardTitle, CardContent, CardFooter } from '@/components/ui/card'
import { Progress } from '@/components/ui/progress'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui/dialog'
import { Textarea } from '@/components/ui/textarea'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'

interface Task {
  id: number | string
  title: string
  type: 'text' | 'voice' | 'image'
  reward_per_task: number
  total_required: number
  completed_count: number
  status: string
}

export default function Tasks() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedTask, setSelectedTask] = useState<Task | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [content, setContent] = useState('')
  const [file, setFile] = useState<File | null>(null)
  const [filterType, setFilterType] = useState<'all' | 'text' | 'voice' | 'image'>('all')
  const [searchQuery, setSearchQuery] = useState('')

  const supabase = useMemo(() => createClient(), [])

  const fetchTasks = useCallback(async () => {
    try {
      const res = await api.listMarketplace()
      if (res && res.items && res.items.length > 0) {
        const backendTasks: Task[] = res.items.map((c: Campaign) => ({
          id: c.id,
          title: c.title,
          type: c.data_type.toLowerCase() as 'text' | 'voice' | 'image',
          reward_per_task:
            typeof c.reward_per_submission === 'string'
              ? parseFloat(c.reward_per_submission)
              : c.reward_per_submission,
          total_required: c.target_submissions,
          completed_count: c.current_submissions,
          status: c.status.toLowerCase(),
        }))
        setTasks(backendTasks)
        setLoading(false)
        return
      }
    } catch {
      // Fallback to supabase datasets
    }

    const { data } = await supabase
      .from('datasets')
      .select('*')
      .eq('status', 'active')
      .order('created_at', { ascending: false })

    if (data) setTasks(data as Task[])
    setLoading(false)
  }, [supabase])

  useEffect(() => {
    let isMounted = true
    const load = async () => {
      try {
        const res = await api.listMarketplace()
        if (res && res.items && res.items.length > 0 && isMounted) {
          const backendTasks: Task[] = res.items.map((c: Campaign) => ({
            id: c.id,
            title: c.title,
            type: c.data_type.toLowerCase() as 'text' | 'voice' | 'image',
            reward_per_task:
              typeof c.reward_per_submission === 'string'
                ? parseFloat(c.reward_per_submission)
                : c.reward_per_submission,
            total_required: c.target_submissions,
            completed_count: c.current_submissions,
            status: c.status.toLowerCase(),
          }))
          setTasks(backendTasks)
          setLoading(false)
          return
        }
      } catch {
        // Fallback to supabase
      }

      const { data } = await supabase
        .from('datasets')
        .select('*')
        .eq('status', 'active')
        .order('created_at', { ascending: false })

      if (data && isMounted) setTasks(data as Task[])
      if (isMounted) setLoading(false)
    }
    load()
    return () => {
      isMounted = false
    }
  }, [supabase])

  const handleTaskSubmit = async () => {
    if (!selectedTask) return
    setSubmitting(true)

    try {
      if (typeof selectedTask.id === 'string') {
        const draft = await api.createSubmissionDraft(selectedTask.id, { text: content })
        if (selectedTask.type !== 'text' && file) {
          const uploadRes = await api.requestMediaUploadUrl(draft.id, {
            filename: file.name,
            mime_type: file.type || (selectedTask.type === 'voice' ? 'audio/wav' : 'image/jpeg'),
            byte_size: file.size,
            asset_type: selectedTask.type === 'voice' ? 'AUDIO' : 'IMAGE',
          })
          await fetch(uploadRes.upload_url, {
            method: 'PUT',
            headers: { 'Content-Type': file.type },
            body: file,
          })
          if (draft.assets && draft.assets.length > 0) {
            await api.confirmMediaUpload(draft.id, draft.assets[0].id)
          }
        }
        await api.submitForValidation(draft.id)
        alert(
          'Submission received! DataMint AI validation engine is evaluating your data. Voucher will be authorized upon approval.'
        )
        setSelectedTask(null)
        setContent('')
        setFile(null)
        fetchTasks()
        return
      }

      const {
        data: { user },
      } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      let fileUrl = ''

      if (selectedTask.type === 'image' || selectedTask.type === 'voice') {
        if (!file) throw new Error('File required')
        const fileName = `${user.id}/${Date.now()}-${file.name}`
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('submissions')
          .upload(fileName, file)

        if (uploadError) throw uploadError
        fileUrl = uploadData.path
      }

      const { error: insertError } = await supabase.from('submissions').insert({
        dataset_id: selectedTask.id,
        user_id: user.id,
        file_url: fileUrl,
        content: selectedTask.type === 'text' ? content : '',
        status: 'pending',
      })

      if (insertError) throw insertError

      const { data: newSub } = await supabase
        .from('submissions')
        .select('id')
        .eq('dataset_id', selectedTask.id)
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(1)
        .single()

      if (newSub?.id) {
        fetch('/api/validate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ submissionId: newSub.id }),
        }).catch(console.error)
      }

      alert('Submission received! AI is validating your data. Reward will be released upon approval.')
      setSelectedTask(null)
      setContent('')
      setFile(null)
      fetchTasks()
    } catch (error: unknown) {
      console.error(error)
      const message = error instanceof Error ? error.message : String(error)
      alert('Submission failed: ' + message)
    } finally {
      setSubmitting(false)
    }
  }

  const filteredTasks = tasks.filter((task) => {
    const matchesFilter = filterType === 'all' || task.type === filterType
    const matchesSearch =
      !searchQuery ||
      task.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      task.type.toLowerCase().includes(searchQuery.toLowerCase())
    return matchesFilter && matchesSearch
  })

  const getTaskIcon = (type: string) => {
    switch (type) {
      case 'voice':
        return 'mic'
      case 'image':
        return 'photo_camera'
      default:
        return 'description'
    }
  }

  return (
    <div className="space-y-8 sm:space-y-10 pb-16">
      {/* Header and Search */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div>
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-white border border-[#BFE3D2] shadow-xs mb-3">
            <span className="w-2 h-2 rounded-full bg-[#0B9E6B] animate-pulse" />
            <span className="material-symbols-rounded text-sm text-[#0D1F18]">paid</span>
            <span className="text-xs font-bold uppercase tracking-wider text-[#3F5F52]">
              Contributor Earnings Marketplace
            </span>
          </div>
          <h1 className="font-bricolage text-3xl sm:text-4xl md:text-5xl font-bold tracking-tight text-[#0D1F18]">
            Available Tasks
          </h1>
          <p className="text-[#3F5F52] text-base sm:text-lg mt-1 max-w-2xl leading-relaxed">
            Contribute voice, text, or visual data to training sets and earn instant cryptographic rewards in cUSD.
          </p>
        </div>

        {/* Search Bar */}
        <div className="w-full md:w-72 relative">
          <span className="material-symbols-rounded absolute left-4 top-1/2 -translate-y-1/2 text-lg text-[#3F5F52] pointer-events-none">
            search
          </span>
          <Input
            placeholder="Search tasks..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-11 pr-4 bg-white shadow-xs"
          />
        </div>
      </div>

      {/* Filter Category Pills */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
        <Button
          variant={filterType === 'all' ? 'default' : 'outline'}
          size="sm"
          className="rounded-full shadow-xs"
          onClick={() => setFilterType('all')}
        >
          All Tasks ({tasks.length})
        </Button>
        <Button
          variant={filterType === 'voice' ? 'default' : 'outline'}
          size="sm"
          className="rounded-full shadow-xs"
          onClick={() => setFilterType('voice')}
        >
          <span className="material-symbols-rounded text-base">mic</span>
          Voice Utterances
        </Button>
        <Button
          variant={filterType === 'image' ? 'default' : 'outline'}
          size="sm"
          className="rounded-full shadow-xs"
          onClick={() => setFilterType('image')}
        >
          <span className="material-symbols-rounded text-base">photo_camera</span>
          Image Samples
        </Button>
        <Button
          variant={filterType === 'text' ? 'default' : 'outline'}
          size="sm"
          className="rounded-full shadow-xs"
          onClick={() => setFilterType('text')}
        >
          <span className="material-symbols-rounded text-base">description</span>
          Text & NLP
        </Button>
      </div>

      {/* Tasks Grid */}
      {loading ? (
        <div className="flex flex-col items-center justify-center py-24 gap-3">
          <div className="w-12 h-12 rounded-full border-4 border-[#74E3B6] border-t-transparent animate-spin" />
          <p className="text-sm font-semibold text-[#3F5F52]">Loading available tasks...</p>
        </div>
      ) : filteredTasks.length === 0 ? (
        <Card className="rounded-[32px] border-2 border-dashed border-[#BFE3D2] bg-white/70 py-16 text-center max-w-xl mx-auto shadow-none">
          <CardContent className="flex flex-col items-center gap-4 text-center p-6">
            <div className="w-16 h-16 rounded-[22px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center text-[#3F5F52]">
              <span className="material-symbols-rounded text-3xl">task_alt</span>
            </div>
            <div>
              <h3 className="font-bricolage text-2xl font-bold text-[#0D1F18]">
                No matching tasks found
              </h3>
              <p className="text-[#3F5F52] text-sm max-w-md mx-auto mt-1 leading-relaxed">
                Try selecting a different category or clearing your search query. New creator requests are posted frequently.
              </p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredTasks.map((task) => {
            const percent = Math.min(
              Math.round(((task.completed_count || 0) / (task.total_required || 1)) * 100),
              100
            )

            return (
              <Card
                key={task.id}
                className="rounded-[32px] border border-[#BFE3D2] bg-white p-6 sm:p-7 shadow-xs hover:shadow-lg transition-all flex flex-col justify-between"
              >
                <div>
                  {/* Top Bar: Icon & Reward Badge */}
                  <div className="flex items-center justify-between gap-3 mb-5">
                    <div className="w-12 h-12 rounded-[16px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center text-[#0D1F18]">
                      <span className="material-symbols-rounded text-2xl">
                        {getTaskIcon(task.type)}
                      </span>
                    </div>

                    <div className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#EAFBF3] border border-[#BFE3D2] text-xs font-bold text-[#0D1F18] shadow-xs">
                      <span className="material-symbols-rounded text-base text-[#0B9E6B]">
                        monetization_on
                      </span>
                      <span>{task.reward_per_task} cUSD</span>
                    </div>
                  </div>

                  {/* Task Title & Details */}
                  <CardTitle className="font-bricolage text-xl sm:text-2xl font-bold text-[#0D1F18] line-clamp-2 leading-snug">
                    {task.title}
                  </CardTitle>

                  <div className="flex items-center gap-2 mt-2">
                    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-slate-50 text-[11px] font-semibold text-[#3F5F52] border border-slate-200 uppercase">
                      {task.type} MODALITY
                    </span>
                    <span className="text-xs text-[#3F5F52]">Escrow secured</span>
                  </div>

                  <p className="text-sm text-[#3F5F52] mt-4 leading-relaxed line-clamp-2">
                    Help build this dataset by contributing high-quality {task.type} data. AI models evaluate submissions in real time.
                  </p>

                  {/* Progress Indicator */}
                  <div className="mt-6 space-y-2">
                    <div className="flex justify-between text-xs font-semibold text-[#3F5F52]">
                      <span>Completion</span>
                      <span className="text-[#0D1F18] font-bold">
                        {task.completed_count || 0} / {task.total_required}{' '}
                        <span className="text-[#3F5F52] font-normal">({percent}%)</span>
                      </span>
                    </div>
                    <Progress value={percent} className="h-2" />
                  </div>
                </div>

                {/* Footer Action */}
                <CardFooter className="p-0 pt-6 mt-6 border-t border-[#BFE3D2]/40">
                  <Button
                    className="w-full rounded-full font-bold shadow-sm"
                    onClick={() => {
                      setSelectedTask(task)
                      setContent('')
                      setFile(null)
                    }}
                  >
                    <span>Accept & Contribute</span>
                    <span className="material-symbols-rounded text-lg">arrow_forward</span>
                  </Button>
                </CardFooter>
              </Card>
            )
          })}
        </div>
      )}

      {/* Submission Dialog Modal */}
      <Dialog open={!!selectedTask} onOpenChange={(open) => !open && setSelectedTask(null)}>
        <DialogContent className="max-w-xl">
          <DialogHeader>
            <div className="flex items-center gap-3 mb-2">
              <div className="w-12 h-12 rounded-[16px] bg-[#EAFBF3] border border-[#BFE3D2] flex items-center justify-center text-[#0D1F18] shrink-0">
                <span className="material-symbols-rounded text-2xl">
                  {selectedTask ? getTaskIcon(selectedTask.type) : 'description'}
                </span>
              </div>
              <div>
                <DialogTitle className="font-bricolage text-2xl font-bold text-[#0D1F18]">
                  Submit {selectedTask?.type?.toUpperCase()} Data
                </DialogTitle>
                <DialogDescription className="text-xs text-[#3F5F52] mt-0.5">
                  Reward:{' '}
                  <span className="font-bold text-[#0D1F18]">
                    {selectedTask?.reward_per_task} cUSD
                  </span>{' '}
                  • Instant AI verification on Celo
                </DialogDescription>
              </div>
            </div>
          </DialogHeader>

          <div className="space-y-6 pt-2">
            <div className="rounded-[22px] bg-[#EAFBF3]/60 border border-[#BFE3D2]/70 p-4">
              <h4 className="text-sm font-bold text-[#0D1F18]">{selectedTask?.title}</h4>
              <p className="text-xs text-[#3F5F52] mt-1 leading-relaxed">
                Please provide authentic, original data.
                {selectedTask?.type === 'voice' &&
                  ' Ensure you record in a quiet room with minimal background noise.'}
                {selectedTask?.type === 'image' &&
                  ' Ensure image files are high resolution and well illuminated.'}
              </p>
            </div>

            {selectedTask?.type === 'text' && (
              <div className="space-y-2">
                <Label htmlFor="content">Text Payload</Label>
                <Textarea
                  id="content"
                  placeholder="Enter or paste your text contribution here..."
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  className="min-h-[140px]"
                />
              </div>
            )}

            {(selectedTask?.type === 'image' || selectedTask?.type === 'voice') && (
              <div className="space-y-2">
                <Label htmlFor="task-file">
                  Upload {selectedTask.type === 'image' ? 'Image File' : 'Voice Audio File'}
                </Label>
                <div className="relative">
                  <input
                    id="task-file"
                    type="file"
                    accept={selectedTask.type === 'image' ? 'image/*' : 'audio/*'}
                    onChange={(e) => setFile(e.target.files?.[0] || null)}
                    className="hidden"
                  />
                  <label
                    htmlFor="task-file"
                    className="flex flex-col items-center justify-center w-full h-40 rounded-[24px] border-2 border-dashed border-[#BFE3D2] bg-[#EAFBF3]/40 hover:bg-[#EAFBF3] transition-colors cursor-pointer p-4 text-center"
                  >
                    <div className="w-12 h-12 rounded-full bg-white border border-[#BFE3D2] flex items-center justify-center text-[#0B9E6B] mb-2 shadow-xs">
                      <span className="material-symbols-rounded text-2xl">upload_file</span>
                    </div>
                    <span className="text-sm font-bold text-[#0D1F18] line-clamp-1">
                      {file ? file.name : `Click or tap to select ${selectedTask.type} asset`}
                    </span>
                    <span className="text-xs text-[#3F5F52] mt-1">
                      {file ? `${(file.size / 1024).toFixed(1)} KB` : 'Max 25MB'}
                    </span>
                  </label>
                </div>
              </div>
            )}
          </div>

          <DialogFooter className="mt-4">
            <Button
              variant="outline"
              className="rounded-full"
              onClick={() => setSelectedTask(null)}
              disabled={submitting}
            >
              Cancel
            </Button>
            <Button
              onClick={handleTaskSubmit}
              disabled={submitting || (!content && !file)}
              className="rounded-full font-bold shadow-sm"
            >
              <span className="material-symbols-rounded text-lg">send</span>
              {submitting ? 'Verifying & Uploading...' : 'Submit Contribution'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
