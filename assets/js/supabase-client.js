const SUPABASE_URL = 'https://jbgzoegggbbmokwignst.supabase.co'
const SUPABASE_ANON_KEY = 'sb_publishable_VzxQdyc2J8zpVXZE41fB0w_p3AxzVv9'

// Ubah nama variabel di sini agar tidak bentrok dengan objek bawaan CDN
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    storageKey: 'stripmate-auth' // (Catatan: perbaiki typo 'stripamate' menjadi 'stripmate' jika ini nama aplikasi aslinya)
  }
})