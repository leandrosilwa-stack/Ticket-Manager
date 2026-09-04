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
  status text not null check (status in ('em atendimento','ag. atendimento','ag. cliente','ações do roteador','concluído','encerrado','resolvido')),
  resolved_at text,
  paused_at text,
  total_paused_ms integer default 0,
  posse_at text,
  tipo text,
  descricao text
);
-- Migração para bases já existentes (idempotente)
alter table public.tickets add column if not exists paused_at text;
alter table public.tickets add column if not exists total_paused_ms integer default 0;
alter table public.tickets add column if not exists posse_at text;
alter table public.tickets add column if not exists tipo text;
alter table public.tickets add column if not exists descricao text;
-- Relaxa check antigo para aceitar novos status (recria se necessário)
alter table public.tickets drop constraint if exists tickets_status_check;
alter table public.tickets add constraint tickets_status_check check (status in ('em atendimento','ag. atendimento','ag. cliente','ações do roteador','concluído','encerrado','resolvido'));
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

-- 4. Tabela slas (para cálculo de vencimento por descrição)
create table if not exists public.slas (
  id text primary key,
  descricao text not null unique,
  prazo_horas integer not null check (prazo_horas > 0)
);
create index if not exists idx_slas_descricao on public.slas(descricao);

-- 5. Tabela feriados (dia/mês sem ano)
create table if not exists public.feriados (
  id text primary key,
  dia integer not null check (dia >= 1 and dia <= 31),
  mes integer not null check (mes >= 1 and mes <= 12),
  descricao text not null,
  unique(dia, mes)
);
create index if not exists idx_feriados_dia_mes on public.feriados(dia, mes);

-- 4. Habilita RLS e cria políticas públicas (anon key pode ler/escrever)
-- Para uso interno/equipe sem auth. Se quiser restringir, ajuste as policies.
alter table public.analysts enable row level security;
alter table public.tickets enable row level security;
alter table public.absences enable row level security;
alter table public.slas enable row level security;
alter table public.feriados enable row level security;

drop policy if exists "Allow all for anon" on public.analysts;
create policy "Allow all for anon" on public.analysts for all using (true) with check (true);

drop policy if exists "Allow all for anon" on public.tickets;
create policy "Allow all for anon" on public.tickets for all using (true) with check (true);

drop policy if exists "Allow all for anon" on public.absences;
create policy "Allow all for anon" on public.absences for all using (true) with check (true);

drop policy if exists "Allow all for anon" on public.slas;
create policy "Allow all for anon" on public.slas for all using (true) with check (true);

drop policy if exists "Allow all for anon" on public.feriados;
create policy "Allow all for anon" on public.feriados for all using (true) with check (true);

-- 5. Habilita Realtime (para sincronização automática entre abas/usuários) - idempotente
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='analysts') then
    alter publication supabase_realtime add table public.analysts;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='tickets') then
    alter publication supabase_realtime add table public.tickets;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='absences') then
    alter publication supabase_realtime add table public.absences;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='slas') then
    alter publication supabase_realtime add table public.slas;
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='feriados') then
    alter publication supabase_realtime add table public.feriados;
  end if;
end $$;

-- 6. Popular analistas padrão (opcional - o app também popula)
insert into public.analysts (name) values
  ('Abraão'),('Ana'),('Daniel'),('Daniella'),('Victor'),
  ('Larissa'),('Leandro'),('Otávio'),('Rafael'),('Raiane'),
  ('Rubens'),('Silvio'),('Wysna')
on conflict (name) do nothing;
