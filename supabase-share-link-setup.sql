-- TOKYO FIELD NOTES 2026 · one-link collaborative editing
-- Run ONCE in a NEW Supabase project SQL Editor. COPY the secret shown by the final SELECT.
-- Anyone with the FULL URL containing #share=SECRET can read and edit this itinerary.
-- Never expose a service_role key in the website.
create extension if not exists pgcrypto;

create table if not exists public.tokyo_shared_board_v1 (
  trip_id text primary key,
  secret_hash text not null,
  revision bigint not null default 0,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.tokyo_shared_board_v1 enable row level security;
revoke all on public.tokyo_shared_board_v1 from public, anon, authenticated;

-- Generate a one-time high-entropy secret. This TEMP table is limited to your SQL session.
create temporary table tokyo_setup_secret as
select encode(gen_random_bytes(32),'hex') as secret;
insert into public.tokyo_shared_board_v1 (trip_id, secret_hash)
select 'tokyo-trip-2026', md5(secret) from tokyo_setup_secret
on conflict (trip_id) do nothing;

create or replace function public.tokyo_read(p_token text)
returns jsonb
language plpgsql security definer set search_path=public,pg_temp
as $$
declare v record;
begin
  if p_token is null or length(p_token) < 40 then return null; end if;
  select revision,state into v
  from public.tokyo_shared_board_v1
  where trip_id='tokyo-trip-2026' and secret_hash=md5(p_token);
  if not found then return null; end if;
  return jsonb_build_object('revision',v.revision,'state',v.state);
end $$;

create or replace function public.tokyo_write(p_token text,p_state jsonb,p_revision bigint)
returns jsonb
language plpgsql security definer set search_path=public,pg_temp
as $$
declare new_revision bigint;
begin
  if p_token is null or length(p_token)<40 then
    raise exception 'INVALID_SHARE_LINK';
  end if;
  if p_state is null or jsonb_typeof(p_state)<>'object' or pg_column_size(p_state)>200000 then
    raise exception 'INVALID_STATE';
  end if;
  update public.tokyo_shared_board_v1
    set state=p_state,revision=revision+1,updated_at=now()
  where trip_id='tokyo-trip-2026'
    and secret_hash=md5(p_token)
    and revision=p_revision
  returning revision into new_revision;
  if not found then raise exception 'VERSION_CONFLICT_OR_INVALID_KEY'; end if;
  return jsonb_build_object('ok',true,'revision',new_revision);
end $$;

revoke execute on function public.tokyo_read(text) from public;
revoke execute on function public.tokyo_write(text,jsonb,bigint) from public;
grant execute on function public.tokyo_read(text) to anon,authenticated;
grant execute on function public.tokyo_write(text,jsonb,bigint) to anon,authenticated;

-- IMPORTANT: Copy the token output below. Keep it private and put it only in the URL fragment.
-- If you re-run this setup after the record exists, the new secret will NOT replace the existing secret.
select secret as YOUR_SHARE_LINK_SECRET from tokyo_setup_secret;
