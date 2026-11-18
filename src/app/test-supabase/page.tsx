import { createClient } from '@/lib/supabase/server'

interface TodoItem {
  id: string | number
  name?: string
}

export default async function Page() {
  const supabase = await createClient()

  // Fetching a 'todos' table, assuming it exists for testing
  const { data: todos, error } = await supabase.from('todos').select()

  if (error) {
    return <div className="p-4 text-red-500">Error: {error.message}</div>
  }

  return (
    <div className="p-8 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Supabase Test</h1>
      {todos && todos.length > 0 ? (
        <ul className="space-y-2">
          {(todos as TodoItem[]).map((todo: TodoItem) => (
            <li key={todo.id} className="p-2 border rounded">
              {todo.name}
            </li>
          ))}
        </ul>
      ) : (
        <p>No todos found or table empty.</p>
      )}
    </div>
  )
}
