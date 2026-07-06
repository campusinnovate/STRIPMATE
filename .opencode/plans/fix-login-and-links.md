# Rencana Perbaikan: Login, Register, dan Link 404

## 1. Fix `assets/js/auth.js`
### a. `register()` — Auto-create profile setelah signUp
Tambahkan insert ke tabel `profiles` setelah `supabase.auth.signUp()`:
```js
async function register(email, password, fullName) {
  const { data, error } = await supabase.auth.signUp({
    email, password,
    options: { data: { full_name: fullName } }
  })
  if (error) throw error

  if (data?.user) {
    await supabase.from('profiles').insert({
      id: data.user.id,
      full_name: fullName,
      email: email,
      role: 'peserta'
    }).maybeSingle()
  }

  return data
}
```

### b. `requireAuth()` — Auto-create profile jika belum ada
```js
async function requireAuth(redirectTo = '/login.html') {
  const user = await getCurrentUser()
  if (!user) {
    window.location.href = redirectTo
    return null
  }
  let profile = await getProfile(user.id)
  if (!profile) {
    await supabase.from('profiles').insert({
      id: user.id,
      email: user.email,
      full_name: user.user_metadata?.full_name || '',
      role: 'peserta'
    }).maybeSingle()
    profile = await getProfile(user.id)
  }
  return { user, profile }
}
```

### c. `getProfile()` — Ganti `.single()` ke `.maybeSingle()` agar tidak error jika tidak ada data
```js
async function getProfile(userId) {
  const { data, error } = await supabase
    .from('profiles').select('*').eq('id', userId).maybeSingle()
  if (error) return null
  return data
}
```

## 2. Fix `login.html`
### a. Redirect admin — `/admin/` → `/admin/index.html`
Baris 114: `window.location.href = '/admin/'` → `window.location.href = '/admin/index.html'`

### b. Handle null profile di handleLogin()
Tambahkan auto-create profile jika profile null (setelah login):
```js
async function handleLogin() {
  const email = document.getElementById('loginEmail').value.trim()
  const password = document.getElementById('loginPassword').value
  if (!email || !password) return showMsg('Isi email dan password.', 'error')
  try {
    const data = await login(email, password)
    let profile = await getProfile(data.user.id)
    
    // Auto-create profile jika belum ada
    if (!profile) {
      await supabase.from('profiles').insert({
        id: data.user.id,
        email: email,
        full_name: '',
        role: 'peserta'
      }).maybeSingle()
      profile = await getProfile(data.user.id)
    }
    
    if (profile && profile.role === 'admin') {
      window.location.href = '/admin/index.html'
    } else {
      window.location.href = '/dashboard.html'
    }
  } catch (e) {
    showMsg(e.message || 'Login gagal. Periksa email dan password.', 'error')
  }
}
```

## 3. Fix `dashboard.html` — Handle null profile di init()
Ubah `init()` untuk handle jika profile null:
```js
async function init() {
  session = await requireAuth('/login.html')
  if (!session) return
  const p = session.profile
  if (!p) {
    document.getElementById('loadingState').innerHTML = '<p>Gagal memuat profil. Silakan login ulang.</p>'
    return
  }
  document.getElementById('userName').textContent = p.full_name || 'Peserta'
  document.getElementById('userInfo').textContent = p.school || 'STRIPMATE Member'
  document.getElementById('loadingState').style.display = 'none'
  document.getElementById('dashContent').style.display = 'block'
  await loadDashboard()
}
```

Juga hapus fungsi `loadBlogPosts()` yang kosong (baris 426-428):
```js
// Hapus atau comment baris 171:
// await loadBlogPosts(),
```

## 4. Tambahan: SQL — Izinkan anon insert ke tabel profiles
Jalankan SQL ini di Supabase SQL Editor untuk mengizinkan anon role insert profile:
```sql
DROP POLICY IF EXISTS "Anonymous users can create profile" ON profiles;
CREATE POLICY "Anonymous users can create profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);
```

Ini sudah ada di rls-policies.sql dengan nama "Users can create own profile" — jadi tidak perlu tambahan.

## 5. Verifikasi
1. Buka halaman login → klik "Daftar" → isi form → klik "Daftar"
2. Cek di Supabase Table Editor → tabel `profiles` → akun baru ada
3. Login dengan akun tersebut → harus masuk dashboard tanpa error
4. Untuk admin: update role ke 'admin' di Table Editor → login → redirect ke `/admin/index.html`
