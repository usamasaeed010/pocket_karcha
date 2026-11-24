-- Run once in Supabase Dashboard → SQL Editor
-- Project: https://zlkgeyknwibaomctzuey.supabase.co

-- 1) Create public bucket (fixes "404 bucket not found")
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'pocket-karcha',
  'pocket-karcha',
  true,
  5242880,
  array['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = true;

-- 2) Policies (safe to re-run — drops old names first)
drop policy if exists "Public read pocket-karcha" on storage.objects;
drop policy if exists "Anon upload pocket-karcha" on storage.objects;
drop policy if exists "Anon update pocket-karcha" on storage.objects;
drop policy if exists "Anon delete pocket-karcha" on storage.objects;

create policy "Public read pocket-karcha"   
on storage.objects for select
to public
using ( bucket_id = 'pocket-karcha' );

create policy "Anon upload pocket-karcha"
on storage.objects for insert
to anon, authenticated
with check ( bucket_id = 'pocket-karcha' );

create policy "Anon update pocket-karcha"
on storage.objects for update
to anon, authenticated
using ( bucket_id = 'pocket-karcha' );

create policy "Anon delete pocket-karcha"
on storage.objects for delete
to anon, authenticated
using ( bucket_id = 'pocket-karcha' );
