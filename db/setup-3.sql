-- =====================================================================
-- MEFG.TECH · Parte 3: precio de cuenta secundaria y descripción del juego
-- Pegar TODO este archivo en Supabase → SQL Editor → New query → Run.
-- No borra nada. Se puede volver a ejecutar.
--   price / old_price           → cuenta PRIMARIA (lo que ya existía)
--   price_sec / old_price_sec   → cuenta SECUNDARIA (opcional: vacío = en la web dice "Consultar stock")
-- =====================================================================

alter table public.products
  add column if not exists price_sec integer check (price_sec is null or price_sec >= 0),
  add column if not exists old_price_sec integer check (old_price_sec is null or old_price_sec >= 0),
  add column if not exists description text;
