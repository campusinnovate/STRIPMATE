-- ============================================
-- RLS POLICIES untuk STRIPMATE
-- Jalankan di Supabase SQL Editor
-- ============================================

-- 1. PROFILES
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can create own profile" ON profiles;
CREATE POLICY "Users can create own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
CREATE POLICY "Admins can update all profiles"
  ON profiles FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- 2. TRIPS
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view trips" ON trips;
CREATE POLICY "Anyone can view trips"
  ON trips FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admins can insert trips" ON trips;
CREATE POLICY "Admins can insert trips"
  ON trips FOR INSERT
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can update trips" ON trips;
CREATE POLICY "Admins can update trips"
  ON trips FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can delete trips" ON trips;
CREATE POLICY "Admins can delete trips"
  ON trips FOR DELETE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- 3. BOOKINGS
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own bookings" ON bookings;
CREATE POLICY "Users can view own bookings"
  ON bookings FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create bookings" ON bookings;
CREATE POLICY "Users can create bookings"
  ON bookings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings;
CREATE POLICY "Admins can view all bookings"
  ON bookings FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can update bookings" ON bookings;
CREATE POLICY "Admins can update bookings"
  ON bookings FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- 4. PAYMENTS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own payments" ON payments;
CREATE POLICY "Users can view own payments"
  ON payments FOR SELECT
  USING (booking_id IN (SELECT id FROM bookings WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Users can create payments" ON payments;
CREATE POLICY "Users can create payments"
  ON payments FOR INSERT
  WITH CHECK (booking_id IN (SELECT id FROM bookings WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Admins can view all payments" ON payments;
CREATE POLICY "Admins can view all payments"
  ON payments FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can update payments" ON payments;
CREATE POLICY "Admins can update payments"
  ON payments FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- 5. BLOG_POSTS (public + admin)
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view published posts" ON blog_posts;
CREATE POLICY "Anyone can view published posts"
  ON blog_posts FOR SELECT
  USING (published = true);

DROP POLICY IF EXISTS "Admins can view all posts" ON blog_posts;
CREATE POLICY "Admins can view all posts"
  ON blog_posts FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can insert posts" ON blog_posts;
CREATE POLICY "Admins can insert posts"
  ON blog_posts FOR INSERT
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can update posts" ON blog_posts;
CREATE POLICY "Admins can update posts"
  ON blog_posts FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can delete posts" ON blog_posts;
CREATE POLICY "Admins can delete posts"
  ON blog_posts FOR DELETE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- 6. E_TICKETS
ALTER TABLE e_tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own tickets" ON e_tickets;
CREATE POLICY "Users can view own tickets"
  ON e_tickets FOR SELECT
  USING (booking_id IN (SELECT id FROM bookings WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Admins can view all tickets" ON e_tickets;
CREATE POLICY "Admins can view all tickets"
  ON e_tickets FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- 7. CERTIFICATES
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own certificates" ON certificates;
CREATE POLICY "Users can view own certificates"
  ON certificates FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can view all certificates" ON certificates;
CREATE POLICY "Admins can view all certificates"
  ON certificates FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- 8. MERCHANDISE
ALTER TABLE merchandise ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own merchandise" ON merchandise;
CREATE POLICY "Users can view own merchandise"
  ON merchandise FOR SELECT
  USING (booking_id IN (SELECT id FROM bookings WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS "Admins can view all merchandise" ON merchandise;
CREATE POLICY "Admins can view all merchandise"
  ON merchandise FOR SELECT
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can update merchandise" ON merchandise;
CREATE POLICY "Admins can update merchandise"
  ON merchandise FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- 9. MEDIA_ASSETS
ALTER TABLE media_assets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view media" ON media_assets;
CREATE POLICY "Anyone can view media"
  ON media_assets FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admins can insert media" ON media_assets;
CREATE POLICY "Admins can insert media"
  ON media_assets FOR INSERT
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can update media" ON media_assets;
CREATE POLICY "Admins can update media"
  ON media_assets FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can delete media" ON media_assets;
CREATE POLICY "Admins can delete media"
  ON media_assets FOR DELETE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- 10. TESTIMONIALS
ALTER TABLE testimonials ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view testimonials" ON testimonials;
CREATE POLICY "Anyone can view testimonials"
  ON testimonials FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admins can insert testimonials" ON testimonials;
CREATE POLICY "Admins can insert testimonials"
  ON testimonials FOR INSERT
  WITH CHECK ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can update testimonials" ON testimonials;
CREATE POLICY "Admins can update testimonials"
  ON testimonials FOR UPDATE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

DROP POLICY IF EXISTS "Admins can delete testimonials" ON testimonials;
CREATE POLICY "Admins can delete testimonials"
  ON testimonials FOR DELETE
  USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
