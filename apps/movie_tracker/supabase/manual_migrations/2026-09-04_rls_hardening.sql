-- CineLog RLS sertlestirme (2026-09-04)
-- Onceki denetimde CRITICAL/HIGH bulgu yok; bunlar sadece en-az-yetki
-- ilkesine yonelik opsiyonel sertlestirmeler. Supabase Dashboard > SQL
-- Editor'da calistir.

-- =====================================================================
-- 1) entries: gereksiz tablo-seviyesi yetkileri kaldir (TRUNCATE vb.)
-- =====================================================================
-- PostgREST REST API zaten TRUNCATE'i hic expose etmiyor, ama dogrudan bir
-- Postgres baglantisi RLS'i tamamen bypass ederek tabloyu tek komutla
-- bosaltabilirdi. SELECT/INSERT/UPDATE/DELETE (RLS ile korunanlar) kalıyor.
revoke truncate, references, trigger on public.entries from anon, authenticated;

-- =====================================================================
-- 2) entries: policy'leri {public} yerine acikca {authenticated}'e kısıtla
-- =====================================================================
drop policy if exists "entries_select_own" on public.entries;
drop policy if exists "entries_insert_own" on public.entries;
drop policy if exists "entries_update_own" on public.entries;
drop policy if exists "entries_delete_own" on public.entries;

create policy "entries_select_own" on public.entries
  for select to authenticated using (auth.uid() = user_id);
create policy "entries_insert_own" on public.entries
  for insert to authenticated with check (auth.uid() = user_id);
create policy "entries_update_own" on public.entries
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "entries_delete_own" on public.entries
  for delete to authenticated using (auth.uid() = user_id);

-- =====================================================================
-- 3) handle_new_user / set_updated_at: PUBLIC/anon/authenticated'den
--    execute iznini kaldir (trigger olarak calismaya devam ederler,
--    sadece dogrudan RPC olarak cagrilamaz hale gelirler - zaten
--    PostgREST bunlari RETURNS trigger oldugu icin RPC olarak
--    listelemiyordu, bu sadece dogrudan DB baglantisi senaryosuna karsi)
-- =====================================================================
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;

-- =====================================================================
-- DOGRULAMA - calistirip ciktiyi yapistir
-- =====================================================================
select 'entries table grants (TRUNCATE/REFERENCES/TRIGGER olmamali)' as check_name,
       coalesce(json_agg(grantee || ':' || privilege_type), '[]'::json) as result
from information_schema.role_table_grants
where table_schema = 'public' and table_name = 'entries'
  and grantee in ('anon','authenticated')
union all
select 'entries policies (roller {authenticated} olmali)',
       coalesce(json_agg(policyname || ':' || roles::text), '[]'::json)
from pg_policies where schemaname='public' and tablename='entries'
union all
select 'handle_new_user / set_updated_at grants (PUBLIC/anon/authenticated olmamali)',
       coalesce(json_agg(grantee || ':' || routine_name), '[]'::json)
from information_schema.role_routine_grants
where routine_name in ('handle_new_user','set_updated_at');
