-- ============================================================
-- CRM LOJISTA — SCHEMA SUPABASE
-- Execute no SQL Editor do Supabase (supabase.com > seu projeto > SQL Editor)
-- ============================================================

-- 1. PROFILES (estende auth.users com dados da loja)
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  store_name text not null default 'Minha Loja',
  owner_name text default '',
  dist_reserva numeric not null default 20,
  dist_prolabore numeric not null default 30,
  dist_reinvestimento numeric not null default 50,
  garantia_padrao_tipo text not null default 'lojista',
  garantia_padrao_meses int not null default 12,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.profiles enable row level security;
create policy "Users see own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Users insert own profile" on public.profiles for insert with check (auth.uid() = id);

-- Trigger: criar perfil automaticamente no registro
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, store_name, owner_name)
  values (new.id, 'Minha Loja', coalesce(new.raw_user_meta_data->>'name', ''));

  -- Categorias padrão
  insert into public.categories (user_id, name, color, icon, sort_order) values
    (new.id, 'Eletrônicos', '#2A4A8C', 'phone', 1),
    (new.id, 'Acessórios', '#7A6F2F', 'tag', 2);

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- 2. CATEGORIAS (o lojista cria as que quiser)
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  name text not null,
  color text default '#2A4A8C',
  icon text default 'tag',
  sort_order int default 0,
  created_at timestamptz default now()
);

alter table public.categories enable row level security;
create policy "Users manage own categories" on public.categories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);


-- 3. CATÁLOGO DE PRODUTOS
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  category_id uuid references public.categories on delete set null,
  name text not null,
  default_cost numeric default 0,
  suggested_price numeric default 0,
  notes text default '',
  active boolean default true,
  created_at timestamptz default now()
);

alter table public.products enable row level security;
create policy "Users manage own products" on public.products
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);


-- 4. VENDAS
create table if not exists public.sales (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  category_id uuid references public.categories on delete set null,
  product_id uuid references public.products on delete set null,
  produto text not null,
  data date,
  nome text default '',
  origem text default '',
  garantia_tipo text default 'lojista',
  garantia_meses int default 12,
  custo_produto numeric default 0,
  frete_seguro numeric default 0,
  brindes numeric default 0,
  reparo numeric default 0,
  uber numeric default 0,
  embalagem numeric default 0,
  valor_venda numeric default 0,
  nf_indicacao numeric default 0,
  status_pagamento text default 'pago' check (status_pagamento in ('pago','parcial','nao_pago')),
  valor_pago numeric default 0,
  num_cliente text default '',
  imei text default '',
  quantidade text default '',
  proxima_compra date,
  obs text default '',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table public.sales enable row level security;
create policy "Users manage own sales" on public.sales
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Índices para performance
create index if not exists idx_sales_user_data on public.sales (user_id, data desc);
create index if not exists idx_sales_user_cat on public.sales (user_id, category_id);
create index if not exists idx_sales_user_status on public.sales (user_id, status_pagamento);


-- 5. MOVIMENTAÇÕES DE ESTOQUE
create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  category_id uuid references public.categories on delete set null,
  tipo text not null check (tipo in ('entrada','saida')),
  item text not null,
  quantidade int default 1,
  valor_unitario numeric default 0,
  data date,
  parceiro text default '',
  obs text default '',
  created_at timestamptz default now()
);

alter table public.stock_movements enable row level security;
create policy "Users manage own stock" on public.stock_movements
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists idx_stock_user on public.stock_movements (user_id, data desc);


-- 6. VIEW: SALDO DE ESTOQUE (agregação automática)
create or replace view public.stock_balance as
select
  user_id,
  item,
  sum(case when tipo='entrada' then quantidade else 0 end) as total_entrada,
  sum(case when tipo='saida' then quantidade else 0 end) as total_saida,
  sum(case when tipo='entrada' then quantidade else 0 end)
    - sum(case when tipo='saida' then quantidade else 0 end) as saldo,
  case
    when sum(case when tipo='entrada' then quantidade else 0 end) > 0
    then sum(case when tipo='entrada' then quantidade * valor_unitario else 0 end)
         / sum(case when tipo='entrada' then quantidade else 0 end)
    else 0
  end as custo_medio
from public.stock_movements
group by user_id, item;


-- ============================================================
-- PRONTO! Agora vá em Authentication > Settings e:
-- 1. Habilite "Email" como provider
-- 2. Desabilite "Confirm email" (pra teste) ou mantenha habilitado (produção)
-- 3. Copie a URL e anon key de Settings > API
-- ============================================================
