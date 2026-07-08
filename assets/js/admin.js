const ADMIN_SIDEBAR = [
  { page: 'dashboard', label: 'Dashboard', icon: '📊', href: 'admin/index.html' },
  { page: 'trips', label: 'Trips', icon: '🗺️', href: 'admin/trips.html' },
  { page: 'bookings', label: 'Bookings', icon: '📋', href: 'admin/bookings.html' },
  { page: 'payments', label: 'Payments', icon: '💰', href: 'admin/payments.html' },
  { page: 'blog', label: 'Blog', icon: '📰', href: 'admin/blog.html' },
  { page: 'media', label: 'Media', icon: '📷', href: 'admin/media.html' },
  { page: 'testimonials', label: 'Testimonials', icon: '💬', href: 'admin/testimonials.html' },
]

function injectSidebar(activePage) {
  const nav = document.querySelector('.admin-sidebar nav')
  if (!nav) return
  nav.innerHTML = ADMIN_SIDEBAR.map(item => `
    <a href="${item.href}" class="${item.page === activePage ? 'active' : ''}">
      <span>${item.icon}</span> ${item.label}
    </a>
  `).join('') + `
    <div class="nav-bottom">
      <a href="index.html" target="_blank">🌐 Lihat Site</a>
      <a href="#" class="logout-link" onclick="logout()">🚪 Logout</a>
    </div>
  `
}

function showToast(message, type = 'success') {
  const existing = document.querySelector('.toast')
  if (existing) existing.remove()
  const toast = document.createElement('div')
  toast.className = `toast toast-${type}`
  toast.textContent = message
  document.body.appendChild(toast)
  requestAnimationFrame(() => toast.classList.add('show'))
  setTimeout(() => {
    toast.classList.remove('show')
    setTimeout(() => toast.remove(), 300)
  }, 3000)
}
