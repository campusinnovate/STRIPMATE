async function register(email, password, fullName) {
  // Gunakan signUp untuk mendaftar, bukan signInWithPassword
  const { data, error } = await supabaseClient.auth.signUp({
    email: email,
    password: password
  })
  
  if (error) throw error

  if (data?.user) {
    // Pastikan pakai supabaseClient
    await supabaseClient.from('profiles').insert({
      id: data.user.id,
      full_name: fullName,
      email: email,
      role: 'peserta'
    }).maybeSingle()
  }

  return data
}

async function login(email, password) {
  // Pastikan pakai supabaseClient
  const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password })
  if (error) throw error
  return data
}

async function logout() {
  try {
    // Pastikan pakai supabaseClient
    await supabaseClient.auth.signOut()
  } catch (e) {
    console.error('Logout error:', e)
  }
  window.location.href = 'login.html'
}

async function getCurrentUser() {
  // Pastikan pakai supabaseClient
  const { data: { user }, error } = await supabaseClient.auth.getUser()
  if (error || !user) return null
  return user
}

async function getProfile(userId) {
  // Pastikan pakai supabaseClient
  const { data, error } = await supabaseClient
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .maybeSingle()
  if (error) return null
  return data
}

async function requireAuth(redirectTo = 'login.html') {
  const user = await getCurrentUser()
  if (!user) {
    window.location.href = redirectTo
    return null
  }
  let profile = await getProfile(user.id)
  if (!profile) {
    // Pastikan pakai supabaseClient
    await supabaseClient.from('profiles').insert({
      id: user.id,
      email: user.email,
      full_name: user.user_metadata?.full_name || '',
      role: 'peserta'
    }).maybeSingle()
    profile = await getProfile(user.id)
  }
  return { user, profile }
}

async function requireAdmin() {
  const session = await requireAuth()
  if (!session) return null
  if (!session.profile || session.profile.role !== 'admin') {
    window.location.href = 'dashboard.html'
    return null
  }
  return session
}

async function updateProfile(userId, data) {
  // Pastikan pakai supabaseClient
  const { error } = await supabaseClient
    .from('profiles')
    .update(data)
    .eq('id', userId)
  if (error) throw error
}

async function uploadFile(bucket, file, path) {
  // Pastikan pakai supabaseClient
  const { data, error } = await supabaseClient.storage
    .from(bucket)
    .upload(path, file)
  if (error) throw error
  
  // Pastikan pakai supabaseClient
  const { data: { publicUrl } } = supabaseClient.storage
    .from(bucket)
    .getPublicUrl(path)
  return publicUrl
}

