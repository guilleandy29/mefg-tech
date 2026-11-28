-- =====================================================================
-- MEFG.TECH · Parte 2: banners, testimonios y configuración
-- Pegar TODO este archivo en Supabase → SQL Editor → New query → Run.
-- Requiere haber ejecutado antes setup.sql. Se puede volver a ejecutar.
-- =====================================================================

-- ---------- Banners del carrusel ----------
create table if not exists public.banners (
  id bigint generated always as identity primary key,
  img text not null,
  alt text not null default '',
  link text,
  active boolean not null default true,
  sort integer not null default 0,
  created_at timestamptz not null default now()
);

-- ---------- Testimonios ----------
create table if not exists public.reviews (
  id bigint generated always as identity primary key,
  name text not null check (length(trim(name)) > 0),
  text text not null check (length(trim(text)) > 0),
  stars integer not null default 5 check (stars between 1 and 5),
  date date not null default current_date,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ---------- Configuración (una sola fila) ----------
create table if not exists public.settings (
  id integer primary key default 1 check (id = 1),
  data jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

drop trigger if exists settings_touch on public.settings;
create trigger settings_touch before update on public.settings
  for each row execute function public.touch_updated_at();

-- ---------- Seguridad (RLS) ----------
alter table public.banners enable row level security;
alter table public.reviews enable row level security;
alter table public.settings enable row level security;

drop policy if exists "todos ven banners activos" on public.banners;
create policy "todos ven banners activos" on public.banners
  for select to anon, authenticated using (active or public.is_admin());
drop policy if exists "admins editan banners" on public.banners;
create policy "admins editan banners" on public.banners
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "todos ven testimonios activos" on public.reviews;
create policy "todos ven testimonios activos" on public.reviews
  for select to anon, authenticated using (active or public.is_admin());
drop policy if exists "admins editan testimonios" on public.reviews;
create policy "admins editan testimonios" on public.reviews
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "todos ven configuracion" on public.settings;
create policy "todos ven configuracion" on public.settings
  for select to anon, authenticated using (true);
drop policy if exists "admins editan configuracion" on public.settings;
create policy "admins editan configuracion" on public.settings
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

grant select on public.banners, public.reviews, public.settings to anon, authenticated;
grant insert, update, delete on public.banners, public.reviews, public.settings to authenticated;

-- ---------- Datos iniciales (lo que ya tenía la web) ----------
do $$
begin
  if not exists (select 1 from public.banners) then
    insert into public.banners (img, alt, link, sort) values
      ('img/banner-lo-mejor-del-anio-2.jpg', 'Ya disponible: lo mejor del año. EA Sports FC 27 y GTA VI para PS4 y PS5', null, 10),
      ('img/banner-mas-vendidos.jpg', 'Los más vendidos: descubrí los juegos del momento. Top semanal', '#vendido', 20),
      ('img/banner-planes-ps-plus-3.jpg', 'Conocé nuestros planes de PlayStation Plus: Essential, Extra y Premium', '#playstation-plus', 30);
  end if;

  if not exists (select 1 from public.reviews) then
    insert into public.reviews (name, text, stars, date) values
      ('Lucas Esteban', '10000/10. La mejor página', 5, current_date - 1),
      ('Thiago Grau', 'Muy barato y es real, recibí las cuentas secundarias aunque como 5 o 7 horas después de que las pedí', 4, current_date - 14),
      ('Tute Serri', 'Siempre han cumplido en tiempo y forma, me generan confianza y les sigo comprando asiduamente', 5, current_date - 15),
      ('Sr Baaan', 'Muy bueno el servicio y rápido la verdad!!! 😁', 5, current_date - 30);
  end if;
end $$;

insert into public.settings (id, data) values (1, jsonb_build_object(
  'whatsapp', '5493513429849',
  'whatsapp_label', '+54 9 351 342-9849',
  'instagram', 'mefg.tech',
  'hours', jsonb_build_array('Lunes a viernes: 11:00 a 19:00 hs', 'Sábados: 10:00 a 13:00 hs'),
  'hours_note', 'Fuera de horario respondemos según disponibilidad.',
  'bf_eyebrow', 'BLACK FRIDAY 🔥',
  'bf_title', '¡Antes que termine! 🕰️',
  'bf_end', to_char((now() + interval '15 days 18 hours') at time zone 'America/Argentina/Cordoba', 'YYYY-MM-DD"T"HH24:MI'),
  'text_slides', true
))
on conflict (id) do nothing;
