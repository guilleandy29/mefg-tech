-- =====================================================================
-- MEFG.TECH · Parte 4: ficha técnica de cada juego
-- Pegar TODO este archivo en Supabase → SQL Editor → New query → Run.
-- No borra nada. Se puede volver a ejecutar. Todos los datos son opcionales.
-- =====================================================================

alter table public.products
  add column if not exists genre text,          -- Ej: Acción, Mundo abierto, Aventura
  add column if not exists size text,           -- Ej: 212 GB
  add column if not exists audio_lang text,     -- Ej: Inglés
  add column if not exists text_lang text,      -- Ej: Español
  add column if not exists local_mp boolean;    -- Multijugador local: sí / no / vacío
