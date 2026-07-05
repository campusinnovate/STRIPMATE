-- ============================================================
-- STRIPMATE — Complete Backend Setup untuk Supabase
-- ============================================================
-- CARA PAKAI:
-- 1. Buka Supabase Dashboard > SQL Editor
-- 2. Paste seluruh isi file ini, lalu klik "Run"
-- 3. Aman dijalankan ulang (idempotent) meskipun tabel sudah ada
--    sebelumnya dari schema.sql versi lama.
-- ============================================================


-- ------------------------------------------------------------
-- 0. EXTENSIONS
-- ------------------------------------------------------------
create extension if not exists "pgcrypto";


-- ------------------------------------------------------------
-- 1. TABLES
-- ------------------------------------------------------------

-- 2.1 PROFILES
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  phone text,
  school text,
  age int,
  domisili text,
  avatar_url text,
  role text default 'user' check (role in ('user','admin')),
  created_at timestamptz default now()
);
alter table profiles add column if not exists updated_at timestamptz default now();

-- 2.2 DESTINATIONS
create table if not exists destinations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  description text,
  location text,
  height text,
  image_url text,
  tags jsonb default '[]',
  tips jsonb default '[]',
  created_at timestamptz default now()
);
alter table destinations add column if not exists updated_at timestamptz default now();

-- 2.3 TRIPS
create table if not exists trips (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique not null,
  destination_id uuid references destinations(id),
  image_url text,
  date date,
  meeting_point text,
  kuota int default 20,
  price numeric(12,2),
  status text default 'open' check (status in ('open', 'closed', 'full')),
  description text,
  facilities jsonb default '[]',
  exclude jsonb default '[]',
  rundown jsonb default '[]',
  created_at timestamptz default now()
);
alter table trips add column if not exists seats_booked int default 0;
alter table trips add column if not exists updated_at timestamptz default now();

-- 2.4 BOOKINGS
create table if not exists bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) not null,
  trip_id uuid references trips(id) not null,
  invoice_number text unique,
  status text default 'pending' check (status in ('pending', 'confirmed', 'cancelled')),
  total_amount numeric(12,2),
  dp_amount numeric(12,2),
  payment_status text default 'dp' check (payment_status in ('dp', 'paid', 'refund')),
  emergency_contact text,
  medical_history text,
  ktp_url text,
  created_at timestamptz default now()
);
alter table bookings add column if not exists updated_at timestamptz default now();

-- 2.5 PAYMENTS
create table if not exists payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references bookings(id) not null,
  method text check (method in ('transfer', 'qris', 'va', 'ewallet')),
  amount numeric(12,2),
  status text default 'pending' check (status in ('pending', 'paid', 'cancelled')),
  proof_url text,
  paid_at timestamptz,
  created_at timestamptz default now()
);

-- 2.6 E_TICKETS
create table if not exists e_tickets (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references bookings(id) not null,
  ticket_number text unique,
  qr_code text,
  issued_at timestamptz default now(),
  valid_until timestamptz
);

-- 2.7 CERTIFICATES
create table if not exists certificates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) not null,
  trip_id uuid references trips(id) not null,
  certificate_number text unique,
  issued_at timestamptz default now(),
  file_url text
);

-- 2.8 MERCHANDISE
create table if not exists merchandise (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references bookings(id) not null,
  item_name text not null,
  quantity int default 1,
  status text default 'pending' check (status in ('pending', 'shipped', 'received'))
);

-- 2.9 BLOG_POSTS
create table if not exists blog_posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  slug text unique not null,
  content text,
  excerpt text,
  image_url text,
  author text default 'STRIPMATE',
  tags jsonb default '[]',
  published boolean default false,
  published_at timestamptz,
  created_at timestamptz default now()
);
alter table blog_posts add column if not exists updated_at timestamptz default now();

-- 2.10 MEDIA_ASSETS
create table if not exists media_assets (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  type text not null check (type in ('press_release', 'logo', 'photo', 'video', 'brand_guideline', 'media_kit')),
  file_url text,
  description text,
  downloadable boolean default true,
  created_at timestamptz default now()
);

-- 2.11 TESTIMONIALS
create table if not exists testimonials (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  trip text,
  content text,
  rating int default 5 check (rating between 1 and 5),
  avatar_url text,
  created_at timestamptz default now()
);


-- ------------------------------------------------------------
-- 2. HELPER FUNCTION: is_admin()
-- ------------------------------------------------------------
-- PENTING: schema.sql lama punya bug "infinite recursion" di policy
-- profiles ("Admins can view all profiles" query ke tabel profiles
-- itu sendiri di dalam RLS-nya sendiri -> bisa error di Postgres).
-- Fungsi SECURITY DEFINER ini menghindari masalah tersebut karena
-- berjalan dengan hak akses super, jadi tidak kena RLS berulang.
-- Diletakkan DI SINI (setelah tabel profiles dibuat) karena fungsi
-- "language sql" divalidasi langsung saat CREATE FUNCTION, jadi
-- tabel yang dirujuk wajib sudah ada duluan.
-- ------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  );
$$;


-- ------------------------------------------------------------
-- 3. ROW LEVEL SECURITY
-- ------------------------------------------------------------
alter table profiles enable row level security;
alter table destinations enable row level security;
alter table trips enable row level security;
alter table bookings enable row level security;
alter table payments enable row level security;
alter table e_tickets enable row level security;
alter table certificates enable row level security;
alter table merchandise enable row level security;
alter table blog_posts enable row level security;
alter table media_assets enable row level security;
alter table testimonials enable row level security;

-- PROFILES
drop policy if exists "Users can view own profile" on profiles;
create policy "Users can view own profile" on profiles for select using (auth.uid() = id);

drop policy if exists "Users can update own profile" on profiles;
create policy "Users can update own profile" on profiles for update using (auth.uid() = id);

drop policy if exists "Admins can view all profiles" on profiles;
create policy "Admins can view all profiles" on profiles for select using (is_admin());

drop policy if exists "Admins can update all profiles" on profiles;
create policy "Admins can update all profiles" on profiles for update using (is_admin());

-- DESTINATIONS
drop policy if exists "Destinations are public" on destinations;
create policy "Destinations are public" on destinations for select using (true);

drop policy if exists "Admins can manage destinations" on destinations;
create policy "Admins can manage destinations" on destinations for all using (is_admin()) with check (is_admin());

-- TRIPS
drop policy if exists "Trips are public" on trips;
create policy "Trips are public" on trips for select using (true);

drop policy if exists "Admins can manage trips" on trips;
create policy "Admins can manage trips" on trips for all using (is_admin()) with check (is_admin());

-- BOOKINGS
drop policy if exists "Users can view own bookings" on bookings;
create policy "Users can view own bookings" on bookings for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own bookings" on bookings;
create policy "Users can insert own bookings" on bookings for insert with check (auth.uid() = user_id);

drop policy if exists "Admins can view all bookings" on bookings;
drop policy if exists "Admins manage all bookings" on bookings;
create policy "Admins manage all bookings" on bookings for all using (is_admin()) with check (is_admin());

-- PAYMENTS
drop policy if exists "Users can view own payments" on payments;
create policy "Users can view own payments" on payments for select using (
  exists (select 1 from bookings where id = booking_id and user_id = auth.uid())
);

drop policy if exists "Users can insert own payments" on payments;
create policy "Users can insert own payments" on payments for insert with check (
  exists (select 1 from bookings where id = booking_id and user_id = auth.uid())
);

drop policy if exists "Admins can manage all payments" on payments;
create policy "Admins can manage all payments" on payments for all using (is_admin()) with check (is_admin());

-- E_TICKETS
drop policy if exists "Users can view own tickets" on e_tickets;
create policy "Users can view own tickets" on e_tickets for select using (
  exists (select 1 from bookings where id = booking_id and user_id = auth.uid())
);

drop policy if exists "Admins can manage tickets" on e_tickets;
create policy "Admins can manage tickets" on e_tickets for all using (is_admin()) with check (is_admin());

-- CERTIFICATES
drop policy if exists "Users can view own certificates" on certificates;
create policy "Users can view own certificates" on certificates for select using (auth.uid() = user_id);

drop policy if exists "Admins can manage certificates" on certificates;
create policy "Admins can manage certificates" on certificates for all using (is_admin()) with check (is_admin());

-- MERCHANDISE
drop policy if exists "Users can view own merchandise" on merchandise;
create policy "Users can view own merchandise" on merchandise for select using (
  exists (select 1 from bookings where id = booking_id and user_id = auth.uid())
);

drop policy if exists "Admins can manage merchandise" on merchandise;
create policy "Admins can manage merchandise" on merchandise for all using (is_admin()) with check (is_admin());

-- BLOG_POSTS
drop policy if exists "Published posts are public" on blog_posts;
create policy "Published posts are public" on blog_posts for select using (published = true or is_admin());

drop policy if exists "Admins can manage posts" on blog_posts;
create policy "Admins can manage posts" on blog_posts for all using (is_admin()) with check (is_admin());

-- MEDIA_ASSETS
drop policy if exists "Media assets are public" on media_assets;
create policy "Media assets are public" on media_assets for select using (true);

drop policy if exists "Admins can manage media" on media_assets;
create policy "Admins can manage media" on media_assets for all using (is_admin()) with check (is_admin());

-- TESTIMONIALS
drop policy if exists "Testimonials are public" on testimonials;
create policy "Testimonials are public" on testimonials for select using (true);

drop policy if exists "Admins can manage testimonials" on testimonials;
create policy "Admins can manage testimonials" on testimonials for all using (is_admin()) with check (is_admin());


-- ------------------------------------------------------------
-- 4. FUNCTIONS & TRIGGERS
-- ------------------------------------------------------------

-- 4.1 Auto-create profile saat user daftar (signup)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 4.2 Auto-update kolom updated_at
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on profiles;
create trigger trg_profiles_updated_at before update on profiles
  for each row execute function public.set_updated_at();

drop trigger if exists trg_destinations_updated_at on destinations;
create trigger trg_destinations_updated_at before update on destinations
  for each row execute function public.set_updated_at();

drop trigger if exists trg_trips_updated_at on trips;
create trigger trg_trips_updated_at before update on trips
  for each row execute function public.set_updated_at();

drop trigger if exists trg_bookings_updated_at on bookings;
create trigger trg_bookings_updated_at before update on bookings
  for each row execute function public.set_updated_at();

drop trigger if exists trg_blog_posts_updated_at on blog_posts;
create trigger trg_blog_posts_updated_at before update on blog_posts
  for each row execute function public.set_updated_at();

-- 4.3 Auto-generate kode unik (invoice, tiket, sertifikat)
-- Sebelumnya generateInvoice() dibuat di sisi client (utils.js).
-- Dengan trigger ini, kode tetap ter-generate otomatis di server
-- walau frontend tidak mengirim nilai invoice_number/ticket_number.
create or replace function public.generate_code(prefix text)
returns text
language plpgsql
as $$
begin
  return prefix || '-' || to_char(now(), 'YYMMDD') || '-' ||
         upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
end;
$$;

create or replace function public.set_invoice_number()
returns trigger
language plpgsql
as $$
begin
  if new.invoice_number is null then
    new.invoice_number := public.generate_code('STR');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_bookings_invoice on bookings;
create trigger trg_bookings_invoice before insert on bookings
  for each row execute function public.set_invoice_number();

create or replace function public.set_ticket_number()
returns trigger
language plpgsql
as $$
begin
  if new.ticket_number is null then
    new.ticket_number := public.generate_code('TIX');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_tickets_number on e_tickets;
create trigger trg_tickets_number before insert on e_tickets
  for each row execute function public.set_ticket_number();

create or replace function public.set_certificate_number()
returns trigger
language plpgsql
as $$
begin
  if new.certificate_number is null then
    new.certificate_number := public.generate_code('CERT');
  end if;
  return new;
end;
$$;

drop trigger if exists trg_certificates_number on certificates;
create trigger trg_certificates_number before insert on certificates
  for each row execute function public.set_certificate_number();

-- 4.4 Sinkronisasi otomatis kuota trip
-- Setiap booking baru/berubah status/dihapus, seats_booked dihitung
-- ulang dari jumlah booking berstatus 'confirmed', dan status trip
-- otomatis berubah jadi 'full' saat kuota penuh (atau balik 'open').
create or replace function public.sync_trip_seats()
returns trigger
language plpgsql
as $$
declare
  v_trip_id uuid;
begin
  v_trip_id := coalesce(new.trip_id, old.trip_id);

  update trips
  set seats_booked = (
    select count(*) from bookings
    where trip_id = v_trip_id and status = 'confirmed'
  )
  where id = v_trip_id;

  update trips
  set status = case
    when seats_booked >= kuota then 'full'
    when status = 'full' and seats_booked < kuota then 'open'
    else status
  end
  where id = v_trip_id;

  return null;
end;
$$;

drop trigger if exists trg_bookings_sync_seats on bookings;
create trigger trg_bookings_sync_seats
  after insert or update of status or delete on bookings
  for each row execute function public.sync_trip_seats();

-- 4.5 Auto isi paid_at saat payment dikonfirmasi jadi 'paid'
create or replace function public.handle_payment_confirmed()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'paid' and old.status is distinct from 'paid' and new.paid_at is null then
    new.paid_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_payments_confirmed on payments;
create trigger trg_payments_confirmed before update on payments
  for each row execute function public.handle_payment_confirmed();

-- 4.6 RPC khusus admin untuk statistik dashboard (dipakai sebagai
-- alternatif query manual di dashboard.html, aman karena dicek is_admin())
create or replace function public.get_admin_dashboard_stats()
returns table(total_users bigint, total_bookings bigint, total_payments bigint, total_revenue numeric)
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_admin() then
    raise exception 'Access denied';
  end if;
  return query
  select
    (select count(*) from profiles),
    (select count(*) from bookings),
    (select count(*) from payments),
    (select coalesce(sum(amount), 0) from payments where status = 'paid');
end;
$$;


-- ------------------------------------------------------------
-- 5. STORAGE BUCKETS
-- ------------------------------------------------------------
-- Dipakai oleh uploadFile() di auth.js. Path file WAJIB diawali
-- folder user_id, contoh: ktp/{user_id}/ktp-budi.jpg
insert into storage.buckets (id, name, public)
values
  ('avatars', 'avatars', true),
  ('ktp', 'ktp', false),
  ('payment-proofs', 'payment-proofs', false),
  ('trip-images', 'trip-images', true),
  ('blog-images', 'blog-images', true),
  ('media-assets', 'media-assets', true),
  ('certificates', 'certificates', false)
on conflict (id) do nothing;

-- AVATARS (publik, hanya pemilik yang bisa upload ke folder-nya)
drop policy if exists "Public read avatars" on storage.objects;
create policy "Public read avatars" on storage.objects for select using (bucket_id = 'avatars');

drop policy if exists "Users upload own avatar" on storage.objects;
create policy "Users upload own avatar" on storage.objects for insert with check (
  bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]
);

-- TRIP IMAGES (publik, hanya admin yang bisa kelola)
drop policy if exists "Public read trip images" on storage.objects;
create policy "Public read trip images" on storage.objects for select using (bucket_id = 'trip-images');

drop policy if exists "Admins manage trip images" on storage.objects;
create policy "Admins manage trip images" on storage.objects for all using (
  bucket_id = 'trip-images' and is_admin()
) with check (bucket_id = 'trip-images' and is_admin());

-- BLOG IMAGES
drop policy if exists "Public read blog images" on storage.objects;
create policy "Public read blog images" on storage.objects for select using (bucket_id = 'blog-images');

drop policy if exists "Admins manage blog images" on storage.objects;
create policy "Admins manage blog images" on storage.objects for all using (
  bucket_id = 'blog-images' and is_admin()
) with check (bucket_id = 'blog-images' and is_admin());

-- MEDIA ASSETS (media center)
drop policy if exists "Public read media assets" on storage.objects;
create policy "Public read media assets" on storage.objects for select using (bucket_id = 'media-assets');

drop policy if exists "Admins manage media assets" on storage.objects;
create policy "Admins manage media assets" on storage.objects for all using (
  bucket_id = 'media-assets' and is_admin()
) with check (bucket_id = 'media-assets' and is_admin());

-- KTP (privat, hanya pemilik & admin)
drop policy if exists "Users upload own ktp" on storage.objects;
create policy "Users upload own ktp" on storage.objects for insert with check (
  bucket_id = 'ktp' and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "Users read own ktp" on storage.objects;
create policy "Users read own ktp" on storage.objects for select using (
  bucket_id = 'ktp' and (auth.uid()::text = (storage.foldername(name))[1] or is_admin())
);

-- PAYMENT PROOFS (privat, hanya pemilik & admin)
drop policy if exists "Users upload own payment proof" on storage.objects;
create policy "Users upload own payment proof" on storage.objects for insert with check (
  bucket_id = 'payment-proofs' and auth.uid()::text = (storage.foldername(name))[1]
);

drop policy if exists "Users read own payment proof" on storage.objects;
create policy "Users read own payment proof" on storage.objects for select using (
  bucket_id = 'payment-proofs' and (auth.uid()::text = (storage.foldername(name))[1] or is_admin())
);

-- CERTIFICATES (privat, hanya pemilik & admin)
drop policy if exists "Users read own certificate" on storage.objects;
create policy "Users read own certificate" on storage.objects for select using (
  bucket_id = 'certificates' and (auth.uid()::text = (storage.foldername(name))[1] or is_admin())
);

drop policy if exists "Admins manage certificates storage" on storage.objects;
create policy "Admins manage certificates storage" on storage.objects for all using (
  bucket_id = 'certificates' and is_admin()
) with check (bucket_id = 'certificates' and is_admin());


-- ------------------------------------------------------------
-- 6. INDEXES
-- ------------------------------------------------------------
create index if not exists idx_bookings_user_id on bookings(user_id);
create index if not exists idx_bookings_trip_id on bookings(trip_id);
create index if not exists idx_bookings_status on bookings(status);
create index if not exists idx_payments_booking_id on payments(booking_id);
create index if not exists idx_payments_status on payments(status);
create index if not exists idx_blog_posts_slug on blog_posts(slug);
create index if not exists idx_blog_posts_published on blog_posts(published);
create index if not exists idx_trips_date on trips(date);
create index if not exists idx_trips_status on trips(status);
create index if not exists idx_trips_slug on trips(slug);

-- ============================================================
-- SELESAI. Backend STRIPMATE siap dipakai.
-- ============================================================