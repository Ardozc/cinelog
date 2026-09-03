-- CineLog guvenlik denetimi duzeltmeleri (2026-09-03)
-- Supabase Dashboard > SQL Editor'da, asagidaki bloklari SIRAYLA calistirin.
-- Bu dosya repoda sadece KAYIT amaclidir; gercek supabase CLI migration'i degildir.

-- =====================================================================
-- BLOK 1: `profiles` tablosunu kimliksiz/anon okumaya tamamen kapat
-- =====================================================================
do $$
declare
  pol record;
begin
  for pol in select policyname from pg_policies
             where schemaname = 'public' and tablename = 'profiles'
  loop
    execute format('drop policy if exists %I on public.profiles', pol.policyname);
  end loop;
end $$;

alter table public.profiles enable row level security;
revoke all on public.profiles from anon, authenticated;

-- =====================================================================
-- BLOK 2: Kullanici adi musaitlik kontrolu - artik tablo degil, RPC
-- =====================================================================
create or replace function public.is_username_available(uname text)
returns boolean
language sql
security definer
set search_path = public, extensions, pg_temp
as $$
  select not exists(select 1 from public.profiles where username = uname);
$$;

revoke all on function public.is_username_available(text) from public;
grant execute on function public.is_username_available(text) to anon, authenticated;

-- =====================================================================
-- BLOK 3: get_email_for_username - artik SIFRE dogrulamasi da istiyor
-- =====================================================================
create extension if not exists pgcrypto;

drop function if exists public.get_email_for_username(text);

create or replace function public.get_email_for_username(uname text, pass text)
returns text
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  found_email text;
  found_hash text;
begin
  select u.email, u.encrypted_password
    into found_email, found_hash
  from auth.users u
  join public.profiles p on p.id = u.id
  where p.username = uname;

  if found_hash is null or pass is null then
    return null;
  end if;

  if found_hash = crypt(pass, found_hash) then
    return found_email;
  end if;

  return null;
end;
$$;

revoke all on function public.get_email_for_username(text, text) from public;
grant execute on function public.get_email_for_username(text, text) to anon, authenticated;

-- =====================================================================
-- BLOK 4: `entries` tablosu - her CRUD icin ayri, net RLS policy
-- =====================================================================
do $$
declare
  pol record;
begin
  for pol in select policyname from pg_policies
             where schemaname = 'public' and tablename = 'entries'
  loop
    execute format('drop policy if exists %I on public.entries', pol.policyname);
  end loop;
end $$;

alter table public.entries enable row level security;

create policy "entries_select_own" on public.entries
  for select using (auth.uid() = user_id);

create policy "entries_insert_own" on public.entries
  for insert with check (auth.uid() = user_id);

create policy "entries_update_own" on public.entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "entries_delete_own" on public.entries
  for delete using (auth.uid() = user_id);

-- =====================================================================
-- BLOK 5: delete_own_account - sadece 'authenticated' cagirabilsin
-- =====================================================================
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

-- =====================================================================
-- BLOK 6: DOGRULAMA
-- =====================================================================
select 'profiles policies (bos olmali)' as check_name,
       coalesce(json_agg(policyname), '[]'::json) as result
from pg_policies where schemaname = 'public' and tablename = 'profiles'
union all
select 'entries policies (4 tane olmali)',
       coalesce(json_agg(policyname), '[]'::json)
from pg_policies where schemaname = 'public' and tablename = 'entries'
union all
select 'get_email_for_username grants (anon+authenticated, sadece 2-arg)',
       coalesce(json_agg(grantee || ':' || routine_name), '[]'::json)
from information_schema.role_routine_grants
where routine_name = 'get_email_for_username'
union all
select 'is_username_available grants (anon+authenticated)',
       coalesce(json_agg(grantee || ':' || routine_name), '[]'::json)
from information_schema.role_routine_grants
where routine_name = 'is_username_available'
union all
select 'delete_own_account grants (sadece authenticated)',
       coalesce(json_agg(grantee || ':' || routine_name), '[]'::json)
from information_schema.role_routine_grants
where routine_name = 'delete_own_account';

select pg_get_functiondef(oid) from pg_proc where proname = 'delete_own_account';
