function showLoading(container, message = 'Memuat...') {
  container.innerHTML = `<div class="loading"><div class="spinner"></div><p>${message}</p></div>`
}

function showEmpty(container, message = 'Belum ada data.') {
  container.innerHTML = `<div class="empty-state"><p>${message}</p></div>`
}

function showError(container, message = 'Terjadi kesalahan.') {
  container.innerHTML = `<div class="error-state"><p>${message}</p></div>`
}

function escapeHtml(str) {
  const div = document.createElement('div')
  div.textContent = str
  return div.innerHTML
}

function debounce(fn, delay = 300) {
  let timer
  return function (...args) {
    clearTimeout(timer)
    timer = setTimeout(() => fn.apply(this, args), delay)
  }
}

function getQueryParam(name) {
  const params = new URLSearchParams(window.location.search)
  return params.get(name)
}

function generateInvoice() {
  return 'STR-' + Date.now().toString(36).toUpperCase() + '-' + Math.random().toString(36).substring(2, 6).toUpperCase()
}

function formatCurrency(amount) {
  if (amount == null || isNaN(amount)) return 'Rp0'
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  }).format(amount)
}

function formatDate(dateStr) {
  if (!dateStr) return '-'
  try {
    return new Date(dateStr).toLocaleDateString('id-ID', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  } catch(e) {
    return '-'
  }
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

function getTicketStatusBadge(status) {
  const badges = {
    active: '<span class="badge badge-paid">Active</span>',
    scanned: '<span class="badge badge-secondary">Scanned</span>'
  }
  return badges[status] || `<span class="badge badge-pending">${status}</span>`
}

function showToast(message, type = 'success') {
  const existing = document.querySelector('.toast-global')
  if (existing) existing.remove()
  const toast = document.createElement('div')
  toast.className = 'toast-global toast-' + type
  const icons = { success: '&#10004;', error: '&#10008;', info: '&#8505;' }
  toast.innerHTML = `<span class="toast-icon">${icons[type] || icons.info}</span><span>${message}</span>`
  Object.assign(toast.style, {
    position:'fixed', bottom:'1.5rem', right:'1.5rem',
    padding:'0.85rem 1.25rem', borderRadius:'0.6rem',
    fontSize:'0.85rem', fontWeight:'600', zIndex:'9999',
    display:'flex', alignItems:'center', gap:'0.5rem',
    background: type === 'error' ? 'rgba(239,68,68,0.95)' : type === 'info' ? 'rgba(27,42,74,0.95)' : 'rgba(45,106,79,0.95)',
    color:'#fff', boxShadow:'0 12px 48px rgba(0,0,0,0.15)',
    backdropFilter:'blur(8px)',
    transform:'translateY(16px)', opacity:'0',
    transition:'all 0.35s cubic-bezier(0.16,1,0.3,1)',
    maxWidth:'420px', border:'1px solid rgba(255,255,255,0.15)'
  })
  document.body.appendChild(toast)
  requestAnimationFrame(() => {
    toast.style.transform = 'translateY(0)'
    toast.style.opacity = '1'
  })
  setTimeout(() => {
    toast.style.transform = 'translateY(16px)'
    toast.style.opacity = '0'
    setTimeout(() => toast.remove(), 400)
  }, 3500)
}

function pageTransition(url) {
  if (!document.getElementById('pageTransitionStyle')) {
    const s = document.createElement('style'); s.id = 'pageTransitionStyle'
    s.textContent = '@keyframes ptSpin{to{transform:rotate(360deg)}}'
    document.head.appendChild(s)
  }
  const overlay = document.createElement('div')
  Object.assign(overlay.style, {
    position:'fixed', inset:'0', zIndex:'9998',
    background:'rgba(27,42,74,0.3)', backdropFilter:'blur(4px)',
    opacity:'0', transition:'opacity 0.25s ease',
    display:'flex', alignItems:'center', justifyContent:'center'
  })
  overlay.innerHTML = '<div style="width:36px;height:36px;border:3px solid rgba(255,255,255,0.2);border-top:3px solid #F97316;border-radius:50%;animation:ptSpin 0.7s linear infinite"></div>'
  document.body.appendChild(overlay)
  requestAnimationFrame(() => overlay.style.opacity = '1')
  setTimeout(() => { window.location.href = url }, 300)
}

function openModal(id) {
  const el = document.getElementById(id)
  if (el) el.classList.add('open')
}

function closeModal(id) {
  const el = document.getElementById(id)
  if (el) el.classList.remove('open')
}

document.addEventListener('click', function(e) {
  if (e.target.classList.contains('modal-overlay')) {
    e.target.classList.remove('open')
  }
})

document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    document.querySelectorAll('.modal-overlay.open').forEach(m => m.classList.remove('open'))
  }
})

function downloadCSV(filename, rows) {
  const csv = rows.map(r => r.map(c => '"' + String(c).replace(/"/g, '""') + '"').join(',')).join('\n')
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = filename
  a.click()
  URL.revokeObjectURL(a.href)
}

;(function initCookieConsent() {
  if (window.location.pathname.startsWith('/admin/')) return
  if (localStorage.getItem('stripmate_cookie_consent')) return

  const style = document.createElement('style')
  style.textContent = `
    #cookieConsent{position:fixed;bottom:0;left:0;right:0;z-index:9995;background:rgba(15,10,5,0.92);backdrop-filter:blur(10px);color:#fff;padding:1rem 1.5rem;font-size:0.85rem;line-height:1.6;display:flex;flex-wrap:wrap;align-items:center;justify-content:space-between;gap:0.75rem;border-top:1px solid rgba(255,255,255,0.08);transform:translateY(100%);transition:transform 0.45s cubic-bezier(0.16,1,0.3,1)}
    #cookieConsent.show{transform:translateY(0)}
    #cookieConsent p{flex:1;min-width:200px;margin:0;color:rgba(255,255,255,0.85)}
    #cookieConsent .cookie-actions{display:flex;gap:0.5rem;flex-shrink:0}
    #cookieConsent .btn-cookie{padding:0.5rem 1.25rem;border-radius:999px;font-size:0.8rem;font-weight:700;cursor:pointer;transition:all.2s;border:none;font-family:inherit}
    #cookieConsent .btn-accept{background:var(--orange,#F97316);color:#fff}
    #cookieConsent .btn-accept:hover{background:var(--orange-light,#FB923C)}
    #cookieConsent .btn-reject{background:transparent;color:rgba(255,255,255,0.7);border:1px solid rgba(255,255,255,0.2)}
    #cookieConsent .btn-reject:hover{background:rgba(255,255,255,0.06);color:#fff}
  `
  document.head.appendChild(style)

  const banner = document.createElement('div')
  banner.id = 'cookieConsent'
  banner.innerHTML = `
    <p>Kami menggunakan cookie untuk meningkatkan pengalaman Anda. Dengan melanjutkan, Anda menyetujui penggunaan cookie kami.</p>
    <div class="cookie-actions">
      <button class="btn-cookie btn-accept" id="cookieAccept">Terima Semua</button>
      <button class="btn-cookie btn-reject" id="cookieReject">Tolak</button>
    </div>
  `
  document.body.appendChild(banner)

  requestAnimationFrame(() => banner.classList.add('show'))

  document.getElementById('cookieAccept').addEventListener('click', function() {
    localStorage.setItem('stripmate_cookie_consent', 'accepted')
    banner.style.transform = 'translateY(100%)'
    setTimeout(() => banner.remove(), 450)
  })

  document.getElementById('cookieReject').addEventListener('click', function() {
    localStorage.setItem('stripmate_cookie_consent', 'rejected')
    banner.style.transform = 'translateY(100%)'
    setTimeout(() => banner.remove(), 450)
  })
})()
