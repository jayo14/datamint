'use client'

import { useState, useEffect, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardContent, CardDescription, CardFooter } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog'
import { Textarea } from '@/components/ui/textarea'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Coins, Zap, Upload, Sparkles, Filter, Search, ArrowRight } from 'lucide-react'

interface Task {
  id: number;
  title: string;
  type: 'text' | 'voice' | 'image';
  reward_per_task: number;
  total_required: number;
  completed_count: number;
  status: string;
}

export default function Tasks() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedTask, setSelectedTask] = useState<Task | null>(null)
  const [submitting, setSubmitting] = useState(false)
  const [content, setContent] = useState('')
  const [file, setFile] = useState<File | null>(null)

  const supabase = createClient()

  const fetchTasks = useCallback(async () => {
    const { data } = await supabase
      .from('datasets')
      .select('*')
      .eq('status', 'active')
      .order('created_at', { ascending: false })

    if (data) setTasks(data as Task[])
    setLoading(false)
  }, [supabase])

  useEffect(() => {
    let isMounted = true;
    const load = async () => {
        const { data } = await supabase
          .from('datasets')
          .select('*')
          .eq('status', 'active')
          .order('created_at', { ascending: false })

        if (data && isMounted) setTasks(data as Task[])
        if (isMounted) setLoading(false)
    }
    load()
    return () => { isMounted = false };
  }, [supabase])

  const handleTaskSubmit = async () => {
    if (!selectedTask) return
    setSubmitting(true)

    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error("Not authenticated")

      let fileUrl = ''

      if (selectedTask.type === 'image' || selectedTask.type === 'voice') {
        if (!file) throw new Error("File required")
        const fileName = `${user.id}/${Date.now()}-${file.name}`
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('submissions')
          .upload(fileName, file)

        if (uploadError) throw uploadError
        fileUrl = uploadData.path
      }

      const { error: insertError } = await supabase
        .from('submissions')
        .insert({
          dataset_id: selectedTask.id,
          user_id: user.id,
          file_url: fileUrl,
          content: selectedTask.type === 'text' ? content : '',
          status: 'pending'
        })

      if (insertError) throw insertError

      // Get the inserted submission ID
      const { data: newSub } = await supabase
        .from('submissions')
        .select('id')
        .eq('dataset_id', selectedTask.id)
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(1)
        .single()

      // Trigger AI validation (non-blocking — show optimistic success message)
      if (newSub?.id) {
        fetch('/api/validate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ submissionId: newSub.id })
        }).catch(console.error) // Fire and forget for demo speed
      }

      alert("Submission received! AI is validating your data. Reward will be released upon approval.")
      setSelectedTask(null)
      setContent('')
      setFile(null)
      fetchTasks()
    } catch (error: unknown) {
      console.error(error)
      const message = error instanceof Error ? error.message : String(error)
      alert("Submission failed: " + message)
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="space-y-10 pb-20 max-w-7xl mx-auto px-4 text-left">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 text-left">
        <div className="space-y-1 text-left">
            <h1 className="text-4xl font-black tracking-tight text-left leading-tight text-left">Available Tasks</h1>
            <p className="text-muted-foreground text-lg font-medium text-left text-base leading-relaxed text-left">Contribute to global AI and earn instant rewards.</p>
        </div>
        <div className="flex items-center gap-3 w-full md:w-auto text-left h-12">
            <div className="relative flex-1 md:w-64 text-left">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <Input placeholder="Search tasks..." className="pl-11 h-12 rounded-full border-none bg-secondary/50 focus-visible:ring-primary h-12 text-sm" />
            </div>
            <Button variant="secondary" size="icon" className="rounded-full h-12 w-12 bg-secondary/50">
                <Filter className="w-5 h-5" />
            </Button>
        </div>
      </div>

      <div className="flex gap-3 overflow-x-auto pb-4 scrollbar-hide text-left">
          <Badge className="px-6 py-2 rounded-full bg-primary text-primary-foreground border-none font-bold whitespace-nowrap h-10 flex items-center">All Tasks</Badge>
          <Badge variant="outline" className="px-6 py-2 rounded-full border-2 border-border font-bold whitespace-nowrap hover:bg-secondary cursor-pointer transition-all h-10 flex items-center text-sm">Voice Collection</Badge>
          <Badge variant="outline" className="px-6 py-2 rounded-full border-2 border-border font-bold whitespace-nowrap hover:bg-secondary cursor-pointer transition-all h-10 flex items-center text-sm">Image Labeling</Badge>
          <Badge variant="outline" className="px-6 py-2 rounded-full border-2 border-border font-bold whitespace-nowrap hover:bg-secondary cursor-pointer transition-all h-10 flex items-center text-sm">Text Analysis</Badge>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20 text-left">
             <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin" />
        </div>
      ) : tasks.length === 0 ? (
        <Card className="border-dashed border-2 bg-transparent rounded-[2.5rem] py-16 text-center text-left mx-auto max-w-2xl bg-white">
          <CardContent className="flex flex-col items-center gap-4 text-center">
            <div className="w-20 h-20 bg-secondary rounded-full flex items-center justify-center text-muted-foreground mx-auto">
                <Sparkles className="w-10 h-10" />
            </div>
            <div className="space-y-1 text-center">
                <h3 className="text-xl font-bold text-center leading-tight">No active tasks</h3>
                <p className="text-muted-foreground max-w-[400px] text-center mx-auto text-base leading-relaxed">Check back later for new opportunities to contribute and earn.</p>
            </div>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 text-left">
          {tasks.map((task) => (
            <Card key={task.id} className="border-none shadow-xl rounded-[2.5rem] overflow-hidden group hover:scale-[1.02] transition-all flex flex-col text-left">
              <CardHeader className="bg-secondary/20 pb-6 pt-8 px-8 border-b border-border/50 text-left">
                <div className="flex justify-between items-start mb-6 text-left">
                    <div className={`w-14 h-14 rounded-2xl flex items-center justify-center shadow-inner ${
                        task.type === 'voice' ? 'bg-amber-100 text-amber-600' :
                        task.type === 'image' ? 'bg-blue-100 text-blue-600' : 'bg-green-100 text-green-600'
                    }`}>
                        {task.type === 'voice' && <Zap className="w-7 h-7" />}
                        {task.type === 'image' && <Upload className="w-7 h-7" />}
                        {task.type === 'text' && <Sparkles className="w-7 h-7" />}
                    </div>
                    <div className="bg-white/80 backdrop-blur-sm px-4 py-2 rounded-full border border-primary/20 shadow-sm flex items-center gap-2 text-left">
                        <Coins className="w-4 h-4 text-primary-foreground" />
                        <span className="font-black text-primary-foreground leading-none text-sm uppercase">{task.reward_per_task} cUSD</span>
                    </div>
                </div>
                <CardTitle className="text-2xl font-black leading-tight tracking-tight group-hover:text-primary-foreground transition-colors text-left leading-none">{task.title}</CardTitle>
                <CardDescription className="text-sm font-bold uppercase tracking-wider text-muted-foreground pt-2 text-left leading-none">
                    {task.type} • MINI-TASK
                </CardDescription>
              </CardHeader>
              <CardContent className="p-8 flex-1 space-y-6 text-left">
                <p className="text-muted-foreground font-medium text-left text-base leading-relaxed">
                  Help build this dataset by contributing high-quality {task.type} data. AI models rely on your input.
                </p>
                <div className="space-y-2 text-left">
                    <div className="flex justify-between text-xs font-black uppercase tracking-widest text-muted-foreground text-left">
                        <span>Completion</span>
                        <span>{Math.round(((task.completed_count || 0) / task.total_required) * 100)}%</span>
                    </div>
                    <div className="h-2 w-full bg-secondary rounded-full overflow-hidden">
                        <div
                            className="h-full bg-primary rounded-full shadow-[0_0_5px_rgba(var(--primary),0.5)]"
                            style={{ width: `${((task.completed_count || 0) / task.total_required) * 100}%` }}
                        />
                    </div>
                </div>
              </CardContent>
              <CardFooter className="px-8 pb-8 pt-0 text-left">
                <Button
                    className="w-full h-14 rounded-2xl font-black text-lg shadow-lg shadow-primary/20 group/btn h-14 bg-primary text-primary-foreground hover:opacity-90"
                    onClick={() => setSelectedTask(task)}
                >
                    Accept & Earn
                    <ArrowRight className="ml-2 w-5 h-5 group-hover/btn:translate-x-1 transition-transform" />
                </Button>
              </CardFooter>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={!!selectedTask} onOpenChange={(open) => !open && setSelectedTask(null)}>
        <DialogContent className="max-w-2xl border-none rounded-[3rem] p-0 overflow-hidden bg-white text-left shadow-2xl">
          <DialogHeader className="p-8 md:p-12 bg-secondary/30 border-b border-border/50 text-left">
            <div className="flex items-center gap-4 mb-4 text-left">
                <div className="w-12 h-12 rounded-2xl bg-white flex items-center justify-center shadow-sm">
                    <Sparkles className="w-6 h-6 text-primary-foreground" />
                </div>
                <div className="text-left">
                    <DialogTitle className="text-3xl font-black tracking-tight leading-none text-left">Submit {selectedTask?.type} Data</DialogTitle>
                    <DialogDescription className="text-base font-bold text-primary-foreground/60 pt-2 text-left leading-none">
                        Reward: {selectedTask?.reward_per_task} cUSD • Global AI Project
                    </DialogDescription>
                </div>
            </div>
          </DialogHeader>

          <div className="p-8 md:p-12 space-y-8 text-left">
            <div className="space-y-2 text-left">
                <h4 className="text-xl font-bold tracking-tight text-left leading-tight">{selectedTask?.title}</h4>
                <p className="text-muted-foreground leading-relaxed text-left text-base">
                    Please provide high-quality data according to the dataset requirements.
                    {selectedTask?.type === 'voice' && " Ensure you are in a quiet environment before recording."}
                    {selectedTask?.type === 'image' && " Ensure images are clear and well-lit."}
                </p>
            </div>

            {selectedTask?.type === 'text' && (
              <div className="space-y-4 text-left">
                <Label htmlFor="content" className="text-lg font-bold text-left block">Your Text Submission</Label>
                <Textarea
                  id="content"
                  placeholder="Enter the required text here..."
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  className="min-h-[200px] rounded-[2rem] bg-secondary/50 border-none p-8 text-lg focus-visible:ring-primary h-48 text-base"
                />
              </div>
            )}

            {(selectedTask?.type === 'image' || selectedTask?.type === 'voice') && (
              <div className="space-y-6 text-left">
                <Label htmlFor="file" className="text-lg font-bold block text-center">Upload {selectedTask.type === 'image' ? 'Image' : 'Audio'}</Label>
                <div className="relative group text-left h-48">
                    <input
                        id="file"
                        type="file"
                        accept={selectedTask.type === 'image' ? 'image/*' : 'audio/*'}
                        onChange={(e) => setFile(e.target.files?.[0] || null)}
                        className="hidden"
                    />
                    <Label
                        htmlFor="file"
                        className="flex flex-col items-center justify-center w-full h-48 rounded-[2rem] border-4 border-dashed border-border group-hover:border-primary/50 transition-all cursor-pointer bg-secondary/20 h-48"
                    >
                        <div className="flex flex-col items-center gap-4 text-muted-foreground group-hover:text-primary-foreground transition-colors text-left">
                            <div className="w-16 h-16 rounded-full bg-white flex items-center justify-center shadow-sm mx-auto">
                                <Upload className="w-8 h-8" />
                            </div>
                            <span className="font-black text-lg text-center mx-auto">{file ? file.name : `Tap to upload ${selectedTask.type}`}</span>
                        </div>
                    </Label>
                </div>
              </div>
            )}
          </div>

          <DialogFooter className="p-8 md:p-12 pt-0 gap-4 flex-col sm:flex-row text-left">
            <Button variant="ghost" className="h-14 rounded-2xl flex-1 font-bold text-lg h-14" onClick={() => setSelectedTask(null)}>Cancel</Button>
            <Button
                onClick={handleTaskSubmit}
                disabled={submitting || (!content && !file)}
                className="h-14 rounded-2xl flex-[2] font-black text-xl shadow-xl shadow-primary/20 h-14 bg-primary text-primary-foreground hover:opacity-90"
            >
              {submitting ? (
                  <div className="flex items-center gap-2">
                      <div className="w-5 h-5 border-3 border-white border-t-transparent rounded-full animate-spin" />
                      Uploading...
                  </div>
              ) : 'Submit Contribution'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
