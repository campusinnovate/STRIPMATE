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
