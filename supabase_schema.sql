create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  username text,
  full_name text,
  avatar_url text,
  bio text,
  tier text not null default 'free',
  role text not null default 'user',
  focus_score int not null default 0,
  streak_days int not null default 0,
  total_tasks int not null default 0,
  completed_tasks int not null default 0,
  focus_hours int not null default 0,
  deep_work_percent int not null default 0,
  admin_percent int not null default 0,
  learning_percent int not null default 0,
  theme_mode text not null default 'dark',
  notifications_enabled boolean not null default true,
  privacy_mode boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  category text not null default 'General',
  priority text not null default 'medium',
  status text not null default 'todo',
  ai_generated boolean not null default false,
  due_date timestamptz,
  created_at timestamptz not null default now()
);

alter table public.users enable row level security;
alter table public.tasks enable row level security;

drop policy if exists "Users can read own profile" on public.users;
create policy "Users can read own profile"
on public.users for select
using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.users;
create policy "Users can insert own profile"
on public.users for insert
with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.users;
create policy "Users can update own profile"
on public.users for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can manage own tasks" on public.tasks;
create policy "Users can manage own tasks"
on public.tasks for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.users (
    id,
    email,
    username,
    full_name,
    tier,
    role,
    updated_at
  ) values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'username',
    new.raw_user_meta_data ->> 'full_name',
    'free',
    'user',
    now()
  )
  on conflict (id) do update set
    email = excluded.email,
    username = excluded.username,
    full_name = excluded.full_name,
    updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
