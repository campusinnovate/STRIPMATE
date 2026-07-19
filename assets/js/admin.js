const ADMIN_SIDEBAR = [
  { page: 'dashboard', label: 'Dashboard', icon: '📊', href: '/admin' },
  { page: 'trips', label: 'Trips', icon: '🗺️', href: '/admin/trips' },
  { page: 'bookings', label: 'Bookings', icon: '📋', href: '/admin/bookings' },
  { page: 'payments', label: 'Payments', icon: '💰', href: '/admin/payments' },
  { page: 'participants', label: 'Peserta', icon: '👥', href: '/admin/participants' },
  { page: 'channels', label: 'Pembayaran', icon: '🏦', href: '/admin/payment-channels' },
  { page: 'calendar', label: 'Kalender', icon: '📅', href: '/admin/calendar' },
  { page: 'blog', label: 'Blog', icon: '📰', href: '/admin/blog' },
  { page: 'media', label: 'Media', icon: '📷', href: '/admin/media' },
  { page: 'testimonials', label: 'Testimonials', icon: '💬', href: '/admin/testimonials' },
  { page: 'scanner', label: 'Scanner', icon: '📷', href: '/admin/scanner' },
]

function injectSidebar(activePage) {
  const nav = document.querySelector('.admin-sidebar nav, .sidebar nav')
  if (!nav) return
  nav.innerHTML = ADMIN_SIDEBAR.map(item => `
    <a href="${item.href}" class="${item.page === activePage ? 'active' : ''}">
      <span>${item.icon}</span> ${item.label}
    </a>
  `).join('') + `
    <div class="nav-bottom">
      <a href="/" target="_blank">🌐 Lihat Site</a>
      <a href="#" class="logout-link" onclick="logout()">🚪 Logout</a>
    </div>
  `
}

;(function injectAdminGate() {
  const style = document.createElement('style')
  style.textContent = `
    .admin-gate{position:fixed;inset:0;z-index:99999;display:flex;flex-direction:column;align-items:center;justify-content:center;background:linear-gradient(135deg,#1B2A4A 0%,#2C4266 100%);color:#fff;font-family:'Plus Jakarta Sans',sans-serif;transition:opacity 0.6s ease,visibility 0.6s ease}
    .admin-gate.hide{opacity:0;visibility:hidden;pointer-events:none}
    .admin-gate .shield{width:64px;height:64px;border-radius:50%;border:3px solid rgba(249,115,22,0.4);display:flex;align-items:center;justify-content:center;font-size:1.8rem;margin-bottom:1rem;animation:shieldPulse 1.5s ease-in-out infinite}
    .admin-gate h2{font-size:1.1rem;font-weight:700;margin-bottom:0.3rem;letter-spacing:-0.01em}
    .admin-gate p{font-size:0.85rem;opacity:0.6}
    .gate-spinner{width:32px;height:32px;border:3px solid rgba(255,255,255,0.15);border-top:3px solid var(--orange,#F97316);border-radius:50%;animation:spin 0.8s linear infinite;margin:0 auto 1rem}
    @keyframes shieldPulse{0%,100%{transform:scale(1);border-color:rgba(249,115,22,0.4)}50%{transform:scale(1.1);border-color:rgba(249,115,22,0.8)}}
    @keyframes spin{to{transform:rotate(360deg)}}
  `
  document.head.appendChild(style)
  const gate = document.createElement('div')
  gate.className = 'admin-gate'
  gate.innerHTML = '<div class="gate-spinner"></div><h2>Mengidentifikasi</h2><p>Memverifikasi akses admin&hellip;</p>'
  document.body.prepend(gate)
  const observer = new MutationObserver(() => {
    if (document.querySelector('.admin-layout, .admin-body, .admin-main')) {
      setTimeout(() => gate.classList.add('hide'), 400)
      observer.disconnect()
    }
  })
  observer.observe(document.body, { childList: true, subtree: true })
  setTimeout(() => { gate.classList.add('hide'); observer.disconnect() }, 6000)
})()
