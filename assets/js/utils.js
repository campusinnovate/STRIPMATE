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
