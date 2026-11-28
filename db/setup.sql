-- =====================================================================
-- MEFG.TECH · Base de datos de la tienda (Supabase)
-- Pegar TODO este archivo en Supabase → SQL Editor → New query → Run.
-- Se puede volver a ejecutar sin romper nada.
-- =====================================================================

-- ---------- Administradores ----------
-- Solo los usuarios que estén en esta tabla pueden editar la tienda.
create table if not exists public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- ---------- Productos ----------
create table if not exists public.products (
  id bigint generated always as identity primary key,
  name text not null check (length(trim(name)) > 0),
  plat text not null check (plat in ('PS3', 'PS4', 'PS5')),
  price integer not null check (price >= 0),
  old_price integer check (old_price is null or old_price >= 0),
  img text,
  in_stock boolean not null default true,
  active boolean not null default true,
  sections text[] not null default '{}',
  sort integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists products_touch on public.products;
create trigger products_touch before update on public.products
  for each row execute function public.touch_updated_at();

-- ---------- Precios de PlayStation Plus ----------
create table if not exists public.ps_prices (
  plan text not null check (plan in ('Essential', 'Extra', 'Premium')),
  months integer not null check (months > 0),
  price integer check (price is null or price >= 0),
  primary key (plan, months)
);

-- ---------- Seguridad (RLS) ----------
alter table public.admins enable row level security;
alter table public.products enable row level security;
alter table public.ps_prices enable row level security;

drop policy if exists "admins ven su fila" on public.admins;
create policy "admins ven su fila" on public.admins
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "todos ven productos visibles" on public.products;
create policy "todos ven productos visibles" on public.products
  for select to anon, authenticated using (active or public.is_admin());

drop policy if exists "admins editan productos" on public.products;
create policy "admins editan productos" on public.products
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "todos ven precios ps plus" on public.ps_prices;
create policy "todos ven precios ps plus" on public.ps_prices
  for select to anon, authenticated using (true);

drop policy if exists "admins editan precios ps plus" on public.ps_prices;
create policy "admins editan precios ps plus" on public.ps_prices
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

grant select on public.products, public.ps_prices to anon, authenticated;
grant insert, update, delete on public.products, public.ps_prices to authenticated;
grant select on public.admins to authenticated;
grant execute on function public.is_admin() to anon, authenticated;

-- ---------- Portadas (Storage) ----------
insert into storage.buckets (id, name, public)
values ('portadas', 'portadas', true)
on conflict (id) do nothing;

drop policy if exists "admins suben portadas" on storage.objects;
create policy "admins suben portadas" on storage.objects
  for insert to authenticated with check (bucket_id = 'portadas' and public.is_admin());

drop policy if exists "admins ven portadas" on storage.objects;
create policy "admins ven portadas" on storage.objects
  for select to authenticated using (bucket_id = 'portadas' and public.is_admin());

drop policy if exists "admins cambian portadas" on storage.objects;
create policy "admins cambian portadas" on storage.objects
  for update to authenticated using (bucket_id = 'portadas' and public.is_admin());

drop policy if exists "admins borran portadas" on storage.objects;
create policy "admins borran portadas" on storage.objects
  for delete to authenticated using (bucket_id = 'portadas' and public.is_admin());

-- ---------- Datos iniciales ----------
insert into public.ps_prices (plan, months) values
  ('Essential', 3), ('Essential', 12), ('Extra', 3), ('Extra', 12), ('Premium', 3), ('Premium', 12)
on conflict do nothing;

-- Los juegos que ya tenía la web (solo se cargan si la tabla está vacía)
do $$
begin
  if not exists (select 1 from public.products) then
    insert into public.products (name, plat, price, old_price, sections, sort) values
      ('Grand Theft Auto V PS5', 'PS5', 7000, 17500, array['black-friday'], 10),
      ('FC26 PS5', 'PS5', 7000, 23400, array['black-friday'], 20),
      ('007 First Light PS5', 'PS5', 23800, 39600, array['black-friday'], 30),
      ('Silent Hill f PS5', 'PS5', 7000, 11600, array['black-friday'], 40),
      ('FC26 Ultimate Edition PS5', 'PS5', 9800, 24500, array['black-friday'], 50),
      ('Assassins Creed Shadows PS5', 'PS5', 7000, 17500, array['black-friday'], 60),
      ('Silent Hill 2 PS5', 'PS5', 7000, 11600, array['black-friday'], 70),
      ('Beast of Reincarnation PS5', 'PS5', 25200, 42000, array['black-friday'], 80),
      ('2 juegos en 1 Mortal Kombat 11 Ultimate más…', 'PS5', 5600, 28000, array['black-friday'], 90),
      ('Cyberpunk 2077: Ultimate Edition PS5', 'PS5', 7000, 35000, array['black-friday'], 100),
      ('Subnautica PS5', 'PS5', 4200, 21000, array['black-friday'], 110),
      ('Metal Gear Solid Delta: Snake Eater PS5', 'PS5', 7000, 23400, array['black-friday'], 120),
      ('Avatar Legends: The Fighting Game PS5', 'PS5', 22400, 32100, array['black-friday'], 130),
      ('The Forest PS5', 'PS5', 2800, 14000, array['black-friday'], 140),
      ('Little Nightmares I y II PS4', 'PS4', 8400, 42000, array['black-friday'], 150),
      ('Astro Bot PS5', 'PS5', 23800, 59500, array['black-friday'], 160),
      ('Poppy Playtime: Chapter 5 PS5', 'PS5', 15400, 25600, array['black-friday'], 170),
      ('Resident Evil 2 PS5', 'PS5', 4200, 14000, array['black-friday'], 180),
      ('Mortal Kombat Legacy Kollection PS4', 'PS4', 14000, 35000, array['black-friday'], 190),
      ('Poppy Playtime: Chapter 4 PS5', 'PS5', 11200, 18600, array['black-friday'], 200),
      ('Code Vein II PS5', 'PS5', 22400, 37400, array['black-friday'], 210),
      ('Hogwarts Legacy Digital Deluxe Edition PS5', 'PS5', 7000, 23400, array['black-friday'], 220),
      ('Mortal Kombat X PS5', 'PS5', 2800, 9400, array['black-friday'], 230),
      ('Little Nightmares I y II PS5', 'PS5', 8400, 21000, array['black-friday'], 240),
      ('FC25 PS5', 'PS5', 1400, 7000, array['vendido-fijos'], 250),
      ('Grand Theft Auto V PS4', 'PS4', 7000, 35000, array['vendido-fijos'], 260),
      ('Crash Team Racing Nitro Fueled PS4', 'PS4', 2800, 14000, array['vendido-fijos'], 270),
      ('God of War III Remastered PS5', 'PS5', 5600, 28000, array['vendido-fijos'], 280),
      ('Mortal Kombat 11 Ultimate PS5', 'PS5', 5600, 28000, array['vendido-fijos'], 290),
      ('The Last of Us Part II PS5', 'PS5', 7000, 35000, array['vendido-fijos'], 300),
      ('Red Dead Redemption 2 PS4', 'PS4', 5600, 28000, array['vendido-fijos', 'vendido-ps4'], 310),
      ('Minecraft PS4', 'PS4', 11200, 37300, array['vendido-fijos', 'vendido-ps4'], 320),
      ('Call of Duty Black Ops III PS3', 'PS3', 1400, 4600, array['vendido-ps3'], 330),
      ('The Last of Us PS3', 'PS3', 1400, 4600, array['vendido-ps3'], 340),
      ('Gran Turismo 6 PS3', 'PS3', 1400, 4600, array['vendido-ps3'], 350),
      ('FIFA 18 PS3', 'PS3', 1400, 4600, array['vendido-ps3'], 360),
      ('Pro Evolution Soccer 2018 PS3', 'PS3', 1400, 4600, array['vendido-ps3'], 370),
      ('God of War Ascension', 'PS3', 1400, 3500, array['vendido-ps3'], 380),
      ('FC27 PS4', 'PS4', 19600, 32600, array['vendido-ps4'], 390),
      ('God of War PS4', 'PS4', 1400, 7000, array['vendido-ps4'], 400),
      ('Marvel''s Spider-Man Game of the Year Edition…', 'PS4', 5600, 28000, array['vendido-ps4'], 410),
      ('Mortal Kombat XL PS4', 'PS4', 2800, 14000, array['vendido-ps4'], 420);
  end if;
end $$;
