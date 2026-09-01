-- Ticket Manager - Supabase Schema
-- Execute este arquivo no Supabase SQL Editor (Dashboard > SQL Editor > New Query)

-- 1. Tabela analysts
create table if not exists public.analysts (
  name text primary key
);

-- 2. Tabela tickets
create table if not exists public.tickets (
  number text primary key,
  analyst text not null,
  open_date text not null,
  due_date text not null,
  date_key text,
  status text not null check (status in ('em atendimento','resolvido')),
  resolved_at text
);
create index if not exists idx_tickets_analyst on public.tickets(analyst);
create index if not exists idx_tickets_status on public.tickets(status);

-- 3. Tabela absences
create table if not exists public.absences (
  id text primary key,
  analyst text not null,
  start_date text not null,
  days integer not null check (days >= 1)
);
create index if not exists idx_absences_analyst on public.absences(analyst);

-- 4. Habilita RLS e cria políticas públicas (anon key pode ler/escrever)
-- Para uso interno/equipe sem auth. Se quiser restringir, ajuste as policies.
alter table public.analysts enable row level security;
alter table public.tickets enable row level security;
alter table public.absences enable row level security;

drop policy if exists "Allow all for anon" on public.analysts;
create policy "Allow all for anon" on public.analysts for all using (true) with check (true);

drop policy if exists "Allow all for anon" on public.tickets;
create policy "Allow all for anon" on public.tickets for all using (true) with check (true);

drop policy if exists "Allow all for anon" on public.absences;
create policy "Allow all for anon" on public.absences for all using (true) with check (true);

-- 5. Habilita Realtime (para sincronização automática entre abas/usuários)
alter publication supabase_realtime add table public.analysts;
alter publication supabase_realtime add table public.tickets;
alter publication supabase_realtime add table public.absences;

-- 6. Popular analistas padrão (opcional - o app também popula)
insert into public.analysts (name) values
  ('Abraão'),('Ana'),('Daniel'),('Daniella'),('Victor'),
  ('Larissa'),('Leandro'),('Otávio'),('Rafael'),('Raiane'),
  ('Rubens'),('Silvio'),('Wysna')
on conflict (name) do nothing;
