async function register(email, password, fullName) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { full_name: fullName } }
  })
  if (error) throw error
  return data
}

async function login(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
  return data
}

async function logout() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
  window.location.href = '/login.html'
}

async function getCurrentUser() {
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) return null
  return user
}

async function getProfile(userId) {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single()
  if (error) return null
  return data
}

async function requireAuth(redirectTo = '/login.html') {
  const user = await getCurrentUser()
  if (!user) {
    window.location.href = redirectTo
    return null
  }
  const profile = await getProfile(user.id)
  return { user, profile }
}

async function requireAdmin() {
  const session = await requireAuth('/login.html')
  if (!session) return null
  if (session.profile.role !== 'admin') {
    window.location.href = '/dashboard.html'
    return null
  }
  return session
}

async function updateProfile(userId, data) {
  const { error } = await supabase
    .from('profiles')
    .update(data)
    .eq('id', userId)
  if (error) throw error
}

async function uploadFile(bucket, file, path) {
  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(path, file)
  if (error) throw error
  const { data: { publicUrl } } = supabase.storage
    .from(bucket)
    .getPublicUrl(path)
  return publicUrl
}

function formatCurrency(amount) {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(amount)
}

function formatDate(dateStr) {
  return new Date(dateStr).toLocaleDateString('id-ID', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

function getStatusBadge(status) {
  const map = {
    pending: '<span class="badge badge-pending">Pending</span>',
    paid: '<span class="badge badge-paid">Paid</span>',
    confirmed: '<span class="badge badge-paid">Confirmed</span>',
    cancelled: '<span class="badge badge-cancelled">Cancelled</span>',
    open: '<span class="badge badge-open">Open Registration</span>',
    closed: '<span class="badge badge-closed">Closed</span>',
    full: '<span class="badge badge-closed">Full</span>',
    dp: '<span class="badge badge-pending">DP</span>',
    refund: '<span class="badge badge-cancelled">Refund</span>',
    shipped: '<span class="badge badge-paid">Shipped</span>',
    received: '<span class="badge badge-open">Received</span>'
  }
  return map[status] || `<span class="badge badge-pending">${status}</span>`
}
