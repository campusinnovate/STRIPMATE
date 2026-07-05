const SUPABASE_URL = 'https://jbgzoeggqbbmokwignst.supabase.co'
const SUPABASE_ANON_KEY = 'sb_publishable_VzxQdyc2J8zpVXZE41fBOw_p3AxzVv9'

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: true,
    storageKey: 'stripamate-auth'
  }
})
