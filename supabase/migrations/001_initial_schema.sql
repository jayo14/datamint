-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Users table (extends Supabase auth.users)
create table if not exists public.users (
  id uuid references auth.users(id) on delete cascade primary key,
  role text not null check (role in ('creator', 'contributor')),
  wallet_address text,
  reputation integer default 0,
  created_at timestamptz default now()
);

-- Datasets table
create table if not exists public.datasets (
  id bigserial primary key,
  creator_id uuid references public.users(id) on delete cascade not null,
  title text not null,
  type text not null check (type in ('text', 'voice', 'image')),
  reward_per_task numeric(10,4) not null default 0.1,
  total_required integer not null default 10,
  completed_count integer default 0,
  status text not null default 'draft' check (status in ('draft', 'active', 'completed')),
  created_at timestamptz default now()
);

-- Submissions table
create table if not exists public.submissions (
  id bigserial primary key,
  dataset_id bigint references public.datasets(id) on delete cascade not null,
  user_id uuid references public.users(id) on delete cascade not null,
  file_url text,
  content text,
  ai_score numeric(4,2),
  ai_feedback text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz default now(),
  unique(dataset_id, user_id)
);

-- Payments table
create table if not exists public.payments (
  id bigserial primary key,
  submission_id bigint references public.submissions(id) on delete set null,
  dataset_id bigint references public.datasets(id) on delete set null,
  wallet_address text not null,
  amount numeric(10,4) not null,
  tx_hash text,
  created_at timestamptz default now()
);

-- RLS Policies
alter table public.users enable row level security;
alter table public.datasets enable row level security;
alter table public.submissions enable row level security;
alter table public.payments enable row level security;

-- Users: read own, insert own
create policy "Users can read own profile" on public.users for select using (auth.uid() = id);
create policy "Users can insert own profile" on public.users for insert with check (auth.uid() = id);
create policy "Users can update own profile" on public.users for update using (auth.uid() = id);

-- Datasets: creators manage own, everyone reads active
create policy "Everyone can view active datasets" on public.datasets for select using (status = 'active' or creator_id = auth.uid());
create policy "Creators can insert datasets" on public.datasets for insert with check (creator_id = auth.uid());
create policy "Creators can update own datasets" on public.datasets for update using (creator_id = auth.uid());

-- Submissions: users see own, dataset creator sees all for their datasets
create policy "Users can view own submissions" on public.submissions for select using (user_id = auth.uid());
create policy "Creators can view submissions on their datasets" on public.submissions for select using (
  exists (select 1 from public.datasets where id = dataset_id and creator_id = auth.uid())
);
create policy "Authenticated users can submit" on public.submissions for insert with check (user_id = auth.uid());
create policy "Creator can update submission status" on public.submissions for update using (
  exists (select 1 from public.datasets where id = dataset_id and creator_id = auth.uid())
);

-- Payments: users see own
create policy "Users can view own payments" on public.payments for select using (wallet_address = (select wallet_address from public.users where id = auth.uid()));
create policy "Service role can insert payments" on public.payments for insert with check (true);

create or replace function increment_completed_count(dataset_id_param bigint)
returns void as $$
  update public.datasets set completed_count = completed_count + 1 where id = dataset_id_param;
$$ language sql security definer;
