-- ============================================
-- COMPLETE SCHEMA untuk STRIPMATE
-- Jalankan di Supabase SQL Editor
-- Urutan: TABLES → RLS POLICIES → SAMPLE DATA
-- ============================================

-- ============================================
-- 1. TABLES (dengan FOREIGN KEY constraints)
-- ============================================

-- EXTENSION untuk UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- PROFILES (extends auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT DEFAULT '',
  email TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  school TEXT DEFAULT '',
  age INTEGER DEFAULT NULL,
  domisili TEXT DEFAULT '',
  role TEXT DEFAULT 'peserta' CHECK (role IN ('peserta', 'admin')),
  avatar_url TEXT DEFAULT '',
  ktp_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- TRIPS
CREATE TABLE IF NOT EXISTS trips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL DEFAULT '',
  slug TEXT UNIQUE DEFAULT '',
  description TEXT DEFAULT '',
  location TEXT DEFAULT '',
  meeting_point TEXT DEFAULT '',
  date DATE DEFAULT NULL,
  price NUMERIC(12,0) DEFAULT 0,
  kuota INTEGER DEFAULT NULL,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'closed', 'full')),
  image_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- BOOKINGS
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  invoice_number TEXT UNIQUE NOT NULL DEFAULT '',
  total_amount NUMERIC(12,0) DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled')),
  payment_status TEXT DEFAULT 'dp' CHECK (payment_status IN ('dp', 'paid', 'refund')),
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PAYMENTS
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  amount NUMERIC(12,0) DEFAULT 0,
  method TEXT DEFAULT 'transfer' CHECK (method IN ('transfer', 'qris', 'va', 'ewallet')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'cancelled')),
  proof_url TEXT DEFAULT '',
  paid_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- BLOG_POSTS
CREATE TABLE IF NOT EXISTS blog_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL DEFAULT '',
  slug TEXT UNIQUE DEFAULT '',
  content TEXT DEFAULT '',
  excerpt TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  author TEXT DEFAULT 'STRIPMATE',
  tags JSONB DEFAULT '[]',
  published BOOLEAN DEFAULT false,
  published_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- E_TICKETS
CREATE TABLE IF NOT EXISTS e_tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  ticket_number TEXT UNIQUE NOT NULL DEFAULT '',
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  qr_url TEXT DEFAULT '',
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'scanned')),
  scanned_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- CERTIFICATES
CREATE TABLE IF NOT EXISTS certificates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  certificate_number TEXT UNIQUE NOT NULL DEFAULT '',
  -- CASCADE handled by the FK constraint above
  issued_at TIMESTAMPTZ DEFAULT NOW(),
  file_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- MERCHANDISE
CREATE TABLE IF NOT EXISTS merchandise (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  item_name TEXT DEFAULT '',
  quantity INTEGER DEFAULT 1,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'shipped', 'received')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- MEDIA_ASSETS
CREATE TABLE IF NOT EXISTS media_assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL DEFAULT '',
  type TEXT DEFAULT 'press_release' CHECK (type IN ('press_release', 'logo', 'photo', 'video', 'brand_guideline', 'media_kit')),
  file_url TEXT DEFAULT '',
  description TEXT DEFAULT '',
  downloadable BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- TESTIMONIALS
CREATE TABLE IF NOT EXISTS testimonials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL DEFAULT '',
  trip TEXT DEFAULT '',
  rating INTEGER DEFAULT 5 CHECK (rating >= 1 AND rating <= 5),
  content TEXT DEFAULT '',
  avatar_url TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. INDEXES untuk performa
-- ============================================
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_trip_id ON bookings(trip_id);
CREATE INDEX IF NOT EXISTS idx_bookings_invoice ON bookings(invoice_number);
CREATE INDEX IF NOT EXISTS idx_payments_booking_id ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_tickets_booking_id ON e_tickets(booking_id);
CREATE INDEX IF NOT EXISTS idx_certificates_user_id ON certificates(user_id);
CREATE INDEX IF NOT EXISTS idx_certificates_trip_id ON certificates(trip_id);
CREATE INDEX IF NOT EXISTS idx_merchandise_booking_id ON merchandise(booking_id);
CREATE INDEX IF NOT EXISTS idx_blog_posts_published ON blog_posts(published) WHERE published = true;
CREATE INDEX IF NOT EXISTS idx_blog_posts_slug ON blog_posts(slug);
CREATE INDEX IF NOT EXISTS idx_trips_date ON trips(date);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);

-- PAYMENT_CHANNELS (dipindah ke sini supaya ada sebelum DO loop trigger)
CREATE TABLE IF NOT EXISTS payment_channels (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL DEFAULT '',
  method TEXT DEFAULT 'transfer' CHECK (method IN ('transfer', 'qris', 'va', 'ewallet')),
  account_name TEXT DEFAULT '',
  account_number TEXT DEFAULT '',
  icon_url TEXT DEFAULT '',
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Fix FK constraints to CASCADE (for existing DBs that lack it)
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_trip_id_fkey;
ALTER TABLE bookings ADD CONSTRAINT bookings_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE;
ALTER TABLE certificates DROP CONSTRAINT IF EXISTS certificates_trip_id_fkey;
ALTER TABLE certificates ADD CONSTRAINT certificates_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE;

-- Add detail columns to trips for rich trip info
ALTER TABLE trips ADD COLUMN IF NOT EXISTS location TEXT DEFAULT '';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS height TEXT DEFAULT '';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS via TEXT DEFAULT '';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS route TEXT DEFAULT '';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS estimate TEXT DEFAULT '';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS rundown JSONB DEFAULT '[]';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS facilities JSONB DEFAULT '[]';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS exclude JSONB DEFAULT '[]';

-- Ensure all tables have updated_at column (safe for existing DB that may lack it)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS ktp_url TEXT DEFAULT '';
ALTER TABLE trips ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE payments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE blog_posts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE e_tickets ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- E-Ticket status tracking columns (v2 migration)
ALTER TABLE e_tickets ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active' CHECK (status IN ('active', 'scanned'));
ALTER TABLE e_tickets ADD COLUMN IF NOT EXISTS scanned_at TIMESTAMPTZ DEFAULT NULL;
UPDATE e_tickets SET status = 'active' WHERE status IS NULL;
ALTER TABLE certificates ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE merchandise ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE media_assets ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE testimonials ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE payment_channels ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ============================================
-- 3. AUTO-UPDATE updated_at TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN SELECT unnest(ARRAY['profiles','trips','bookings','payments','blog_posts','merchandise','media_assets','testimonials','payment_channels'])
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_%s_updated_at ON %s', tbl, tbl);
    EXECUTE format('CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON %s FOR EACH ROW EXECUTE FUNCTION update_updated_at()', tbl, tbl);
  END LOOP;
END;
$$;

-- AUTO trip status = 'full' when confirmed bookings >= kuota
CREATE OR REPLACE FUNCTION check_trip_full()
RETURNS TRIGGER AS $$
DECLARE
  t_kuota INTEGER;
  confirmed_count INTEGER;
BEGIN
  SELECT kuota INTO t_kuota FROM trips WHERE id = NEW.trip_id;
  SELECT COUNT(*) INTO confirmed_count
    FROM bookings
    WHERE trip_id = NEW.trip_id AND status = 'confirmed';
  IF confirmed_count >= t_kuota AND t_kuota > 0 THEN
    UPDATE trips SET status = 'full' WHERE id = NEW.trip_id;
  ELSE
    UPDATE trips SET status = 'open' WHERE id = NEW.trip_id AND status = 'full';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_trip_full ON bookings;
CREATE TRIGGER trg_check_trip_full
  AFTER INSERT OR UPDATE OF status ON bookings
  FOR EACH ROW EXECUTE FUNCTION check_trip_full();

-- AUTO generate e-ticket when payment is confirmed
CREATE OR REPLACE FUNCTION auto_generate_e_ticket()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.payment_status = 'paid' AND (OLD.payment_status IS DISTINCT FROM 'paid') THEN
    INSERT INTO e_tickets (booking_id, ticket_number)
    VALUES (
      NEW.id,
      'TKT-' || upper(substr(md5(random()::text), 1, 8)) || '-' || upper(substr(md5(random()::text), 1, 4))
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_auto_e_ticket ON bookings;
CREATE TRIGGER trg_auto_e_ticket
  AFTER UPDATE OF payment_status ON bookings
  FOR EACH ROW EXECUTE FUNCTION auto_generate_e_ticket();

-- ============================================
-- 4. RLS POLICIES (idempotent)
-- ============================================

-- Helper: admin check function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- PROFILES
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profiles_select_own" ON profiles; CREATE POLICY "profiles_select_own" ON profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "profiles_insert_own" ON profiles; CREATE POLICY "profiles_insert_own" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "profiles_update_own" ON profiles; CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "profiles_select_admin" ON profiles; CREATE POLICY "profiles_select_admin" ON profiles FOR SELECT USING (public.is_admin());
DROP POLICY IF EXISTS "profiles_update_admin" ON profiles; CREATE POLICY "profiles_update_admin" ON profiles FOR UPDATE USING (public.is_admin());

-- TRIPS
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "trips_select_all" ON trips; CREATE POLICY "trips_select_all" ON trips FOR SELECT USING (true);
DROP POLICY IF EXISTS "trips_insert_admin" ON trips; CREATE POLICY "trips_insert_admin" ON trips FOR INSERT WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "trips_update_admin" ON trips; CREATE POLICY "trips_update_admin" ON trips FOR UPDATE USING (public.is_admin());
DROP POLICY IF EXISTS "trips_delete_admin" ON trips; CREATE POLICY "trips_delete_admin" ON trips FOR DELETE USING (public.is_admin());

-- BOOKINGS
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "bookings_select_own" ON bookings; CREATE POLICY "bookings_select_own" ON bookings FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "bookings_insert_own" ON bookings; CREATE POLICY "bookings_insert_own" ON bookings FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "bookings_select_admin" ON bookings; CREATE POLICY "bookings_select_admin" ON bookings FOR SELECT USING (public.is_admin());
DROP POLICY IF EXISTS "bookings_update_admin" ON bookings; CREATE POLICY "bookings_update_admin" ON bookings FOR UPDATE USING (public.is_admin());

-- PAYMENTS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "payments_select_own" ON payments; CREATE POLICY "payments_select_own" ON payments FOR SELECT USING (booking_id IN (SELECT id FROM bookings WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "payments_insert_own" ON payments; CREATE POLICY "payments_insert_own" ON payments FOR INSERT WITH CHECK (booking_id IN (SELECT id FROM bookings WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "payments_select_admin" ON payments; CREATE POLICY "payments_select_admin" ON payments FOR SELECT USING (public.is_admin());
DROP POLICY IF EXISTS "payments_update_admin" ON payments; CREATE POLICY "payments_update_admin" ON payments FOR UPDATE USING (public.is_admin());

-- BLOG_POSTS
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "blog_select_published" ON blog_posts; CREATE POLICY "blog_select_published" ON blog_posts FOR SELECT USING (published = true);
DROP POLICY IF EXISTS "blog_select_admin" ON blog_posts; CREATE POLICY "blog_select_admin" ON blog_posts FOR SELECT USING (public.is_admin());
DROP POLICY IF EXISTS "blog_insert_admin" ON blog_posts; CREATE POLICY "blog_insert_admin" ON blog_posts FOR INSERT WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "blog_update_admin" ON blog_posts; CREATE POLICY "blog_update_admin" ON blog_posts FOR UPDATE USING (public.is_admin());
DROP POLICY IF EXISTS "blog_delete_admin" ON blog_posts; CREATE POLICY "blog_delete_admin" ON blog_posts FOR DELETE USING (public.is_admin());

-- E_TICKETS
ALTER TABLE e_tickets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tickets_select_own" ON e_tickets; CREATE POLICY "tickets_select_own" ON e_tickets FOR SELECT USING (booking_id IN (SELECT id FROM bookings WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "tickets_select_admin" ON e_tickets; CREATE POLICY "tickets_select_admin" ON e_tickets FOR SELECT USING (public.is_admin());
DROP POLICY IF EXISTS "tickets_update_admin" ON e_tickets; CREATE POLICY "tickets_update_admin" ON e_tickets FOR UPDATE USING (public.is_admin());

-- CERTIFICATES
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "certs_select_own" ON certificates; CREATE POLICY "certs_select_own" ON certificates FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS "certs_select_admin" ON certificates; CREATE POLICY "certs_select_admin" ON certificates FOR SELECT USING (public.is_admin());

-- MERCHANDISE
ALTER TABLE merchandise ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "merch_select_own" ON merchandise; CREATE POLICY "merch_select_own" ON merchandise FOR SELECT USING (booking_id IN (SELECT id FROM bookings WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "merch_select_admin" ON merchandise; CREATE POLICY "merch_select_admin" ON merchandise FOR SELECT USING (public.is_admin());
DROP POLICY IF EXISTS "merch_update_admin" ON merchandise; CREATE POLICY "merch_update_admin" ON merchandise FOR UPDATE USING (public.is_admin());

-- MEDIA_ASSETS
ALTER TABLE media_assets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "media_select_all" ON media_assets; CREATE POLICY "media_select_all" ON media_assets FOR SELECT USING (true);
DROP POLICY IF EXISTS "media_insert_admin" ON media_assets; CREATE POLICY "media_insert_admin" ON media_assets FOR INSERT WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "media_update_admin" ON media_assets; CREATE POLICY "media_update_admin" ON media_assets FOR UPDATE USING (public.is_admin());
DROP POLICY IF EXISTS "media_delete_admin" ON media_assets; CREATE POLICY "media_delete_admin" ON media_assets FOR DELETE USING (public.is_admin());

-- PAYMENT_CHANNELS
ALTER TABLE payment_channels ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pc_select_active" ON payment_channels; CREATE POLICY "pc_select_active" ON payment_channels FOR SELECT USING (is_active = true OR public.is_admin());
DROP POLICY IF EXISTS "pc_insert_admin" ON payment_channels; CREATE POLICY "pc_insert_admin" ON payment_channels FOR INSERT WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "pc_update_admin" ON payment_channels; CREATE POLICY "pc_update_admin" ON payment_channels FOR UPDATE USING (public.is_admin());
DROP POLICY IF EXISTS "pc_delete_admin" ON payment_channels; CREATE POLICY "pc_delete_admin" ON payment_channels FOR DELETE USING (public.is_admin());

-- TESTIMONIALS
ALTER TABLE testimonials ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "testi_select_all" ON testimonials; CREATE POLICY "testi_select_all" ON testimonials FOR SELECT USING (true);
DROP POLICY IF EXISTS "testi_insert_admin" ON testimonials; CREATE POLICY "testi_insert_admin" ON testimonials FOR INSERT WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS "testi_update_admin" ON testimonials; CREATE POLICY "testi_update_admin" ON testimonials FOR UPDATE USING (public.is_admin());
DROP POLICY IF EXISTS "testi_delete_admin" ON testimonials; CREATE POLICY "testi_delete_admin" ON testimonials FOR DELETE USING (public.is_admin());

-- Create storage buckets (run in Supabase SQL Editor)
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
DROP POLICY IF EXISTS "avatars_public_select" ON storage.objects; CREATE POLICY "avatars_public_select" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
DROP POLICY IF EXISTS "avatars_auth_insert" ON storage.objects; CREATE POLICY "avatars_auth_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
DROP POLICY IF EXISTS "avatars_own_update" ON storage.objects; CREATE POLICY "avatars_own_update" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND owner = auth.uid());

INSERT INTO storage.buckets (id, name, public) VALUES ('payments', 'payments', true) ON CONFLICT DO NOTHING;
DROP POLICY IF EXISTS "payments_public_select" ON storage.objects; CREATE POLICY "payments_public_select" ON storage.objects FOR SELECT USING (bucket_id = 'payments');
DROP POLICY IF EXISTS "payments_auth_insert" ON storage.objects; CREATE POLICY "payments_auth_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'payments' AND auth.role() = 'authenticated');
DROP POLICY IF EXISTS "payments_own_update" ON storage.objects; CREATE POLICY "payments_own_update" ON storage.objects FOR UPDATE USING (bucket_id = 'payments' AND owner = auth.uid());

-- ============================================
-- 5. SAMPLE DATA (testing purposes)
-- ============================================

-- Sample Trips
INSERT INTO trips (title, slug, description, location, meeting_point, date, price, kuota, status, image_url, height, via, route, estimate, rundown, facilities, exclude) VALUES
  ('Gunung Papandayan', 'papandayan', 'Gunung Papandayan (2.665 MDPL) di Garut, Jawa Barat. Dikenal dengan Hutan Mati yang surreal dan sunrise di Tegal Alun.', 'Garut, Jawa Barat', 'Bogor', '2026-08-15', 369000, 17, 'open', 'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=600&q=80', '2.665 MDPL', 'Travel Elf dari Meeting Point', 'Mulai dari Warung Haur Luwung, tracking 3-4 jam', 'Pendakian 3-4 jam, turun 2-3 jam', '["18.00 - Meeting Point Bogor","18.30 - Berangkat ke Garut","23.00 - Tiba di Basecamp, briefing","00.00 - Mulai pendakian","04.00 - Tiba di Tegal Alun, rest","05.00 - Sunrise & foto","07.00 - Breakfast & explore Hutan Mati","09.00 - Turun","12.00 - Tiba di basecamp, makan","13.00 - Perjalanan pulang","18.00 - Tiba di Bogor"]', '["Transport PP","Tiket masuk","Konsumsi 1x","Dokumentasi","Tour Leader","P3K"]', '["Pengeluaran pribadi","Obat pribadi","Sewa alat"]'),
  ('Gunung Prau', 'prau', 'Gunung Prau (2.565 MDPL) di Dieng. Padang rumput luas di puncak dengan pemandangan 7 gunung.', 'Dieng, Jawa Tengah', 'Wonosobo', '2026-09-05', 399000, 20, 'open', 'https://images.unsplash.com/photo-1585409677983-0f6c41ca9c3b?w=600&q=80', '2.565 MDPL', 'Travel Elf dari Meeting Point', 'Mulai dari Patak Banteng, tracking 1.5-2 jam', 'Pendakian 1.5-2 jam (termudah)', '[]', '["Transport PP","Tiket masuk","Konsumsi 1x","Dokumentasi","Tour Leader","P3K"]', '["Pengeluaran pribadi","Obat pribadi","Sewa tenda"]'),
  ('Gunung Bromo', 'bromo', 'Gunung Bromo (2.329 MDPL). Sunrise epic, lautan pasir, dan kawah aktif.', 'Malang, Jawa Timur', 'Malang', '2026-10-10', 499000, 12, 'open', 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600&q=80', '2.329 MDPL', 'Jeep + Travel dari Meeting Point', 'Jeep dari Cemoro Lawang ke lautan pasir, lalu trek singkat ke kawah', 'Full day explore dengan Jeep', '[]', '["Transport PP","Tiket masuk","Sewa Jeep","Konsumsi 1x","Dokumentasi","Tour Leader","P3K"]', '["Pengeluaran pribadi","Obat pribadi","Sewa jaket"]'),
  ('Karimunjawa', 'karimunjawa', 'Karimunjawa, surga tropis dengan pasir putih, snorkeling, dan sunset.', 'Jepara, Jawa Tengah', 'Semarang', '2026-07-20', 599000, 15, 'open', 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80', '0 MDPL (Pantai)', 'Bus + Ferry dari Meeting Point', 'Dari Semarang naik bus ke Jepara, lalu ferry ke Karimunjawa', '3 hari 2 malam', '[]', '["Transport PP","Tiket ferry","Penginapan 2 malam","Makan 3x","Snorkeling gear","Tour Guide","Dokumentasi"]', '["Pengeluaran pribadi","Obat pribadi","Souvenir"]'),
  ('Dieng Plateau', 'dieng', 'Dieng Plateau (2.093 MDPL). Candi, kawah, telaga warna, dan golden sunrise.', 'Wonosobo, Jawa Tengah', 'Wonosobo', '2026-08-28', 349000, 20, 'open', 'https://images.unsplash.com/photo-1454496522488-7a8e488e8606?w=600&q=80', '2.093 MDPL', 'Travel Elf dari Meeting Point', 'Mobil dari Wonosobo, explore berbagai spot dengan kendaraan', '2 hari 1 malam (full explore)', '[]', '["Transport PP","Tiket masuk semua spot","Penginapan 1 malam","Makan 2x","Tour Guide","Dokumentasi","P3K"]', '["Pengeluaran pribadi","Obat pribadi","Sewa jaket"]')
ON CONFLICT (slug) DO NOTHING;

-- Sample Blog Posts
INSERT INTO blog_posts (title, slug, content, excerpt, author, tags, published, published_at, image_url) VALUES
  ('Tips Hiking Pertama untuk Pemula', 'tips-hiking-pemula',
   '<h2>Persiapan Mental dan Fisik</h2><p>Hiking pertama memang menantang, tapi dengan persiapan yang tepat, kamu pasti bisa! Berikut tips dari tim STRIPMATE untuk para pendaki pemula.</p><h2>Perlengkapan Wajib</h2><p>Sepatu trekking, jaket, air minum minimal 2 liter, snack energi, senter, dan obat pribadi adalah barang wajib yang harus dibawa.</p><h2>Atur Ritme</h2><p>Jangan terburu-buru. Atur napas, istirahat setiap 15-20 menit, dan nikmati perjalanan. Ingat, hiking bukan lomba!</p>',
   'Persiapan mental, fisik, dan perlengkapan wajib untuk pengalaman hiking pertama yang aman dan menyenangkan.',
   'STRIPMATE', '["tips","hiking","pemula","outdoor"]', true, NOW() - INTERVAL '7 days',
   'https://images.unsplash.com/photo-1551632811-561732d1e306?w=600&q=80'),

  ('5 Destinasi Gunung untuk Pemula di Jawa', 'destinasi-gunung-pemula',
   '<h2>Gunung Ramah untuk Pendaki Pemula</h2><p>Ingin mulai hobi mendaki gunung tapi bingung mulai dari mana? Berikut 5 rekomendasi gunung yang cocok untuk pemula.</p><h2>1. Gunung Prau (2.565 MDPL)</h2><p>Jalur termudah, hanya 1.5 jam dari Patak Banteng. Puncak berupa padang rumput luas.</p><h2>2. Gunung Papandayan (2.665 MDPL)</h2><p>Tracking 3-4 jam dengan pemandangan hutan mati yang eksotis.</p>',
   'Rekomendasi gunung ramah pemula di Pulau Jawa dengan jalur pendakian yang relatif mudah.',
   'STRIPMATE', '["gunung","pemula","destinasi","trekking"]', true, NOW() - INTERVAL '3 days',
   'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&q=80'),

  ('Cerita Peserta: Pengalaman Pertama ke Bromo', 'cerita-peserta-bromo',
   '<p>"Awalnya ragu karena belum pernah mendaki, tapi trip Bromo bareng STRIPMATE bikin aku ketagihan!" — Andi, peserta Bromo STRIPMATE September 2025.</p><p>Sunrise di Bukit Penanjakan, berfoto di lautan pasir, dan melihat kawah Bromo dari dekat adalah pengalaman yang nggak bisa dilupakan.</p>',
   'Kesan dan pengalaman seru peserta STRIPMATE selama trip ke Gunung Bromo.',
   'STRIPMATE', '["cerita","peserta","bromo","pengalaman"]', true, NOW() - INTERVAL '1 day',
   'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600&q=80')
ON CONFLICT (slug) DO NOTHING;

-- Sample Testimonials
INSERT INTO testimonials (name, trip, rating, content, avatar_url) VALUES
  ('Sarah Azzahra', 'Gunung Papandayan', 5, 'Seru banget! Pertama kali naik gunung, awalnya takut tapi Trip Leadernya asik banget dan selalu ngebimbing. Pemandangan di puncak bener-bener wow!', 'https://i.pravatar.cc/80?img=1'),
  ('Raka Pratama', 'Gunung Bromo', 5, 'Bromo bareng STRIPMATE pengalaman yang nggak bakal terlupakan. Sunrise-nya juara! Dapet temen baru dari berbagai kampus juga.', 'https://i.pravatar.cc/80?img=3'),
  ('Dewi Lestari', 'Gunung Prau', 5, 'Prau puncaknya indah banget! Padang rumput luas, cocok buat foto-foto. Thanks STRIPMATE udah bikin trip yang aman dan seru!', 'https://i.pravatar.cc/80?img=5'),
  ('Fajar Ramadhan', 'Dieng Plateau', 4, 'Dieng keren! Telaga Warna dan golden sunrise-nya epic. Satu lagi destinasi yang wajib dikunjungi.', 'https://i.pravatar.cc/80?img=8'),
  ('Nurul Hidayah', 'Karimunjawa', 5, 'Karimunjawa surga banget! Snorkeling, island hopping, sunset. All in one trip. Makasih STRIPMATE!', 'https://i.pravatar.cc/80?img=9'),
  ('Budi Santoso', 'Gunung Papandayan', 5, 'Trip kedua bareng STRIPMATE dan selalu memuaskan. Organisasinya rapi, komunikatif, dan harga terjangkau untuk pelajar.', 'https://i.pravatar.cc/80?img=11')
ON CONFLICT DO NOTHING;
