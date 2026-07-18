function initWhatsApp() {
  const btn = document.createElement('a')
  btn.href = 'https://wa.me/6289647188725?text=Halo%20STRIPMATE%2C%20saya%20mau%20tanya%20trip!'
  btn.target = '_blank'
  btn.rel = 'noopener'
  btn.setAttribute('aria-label', 'Chat WhatsApp')
  btn.innerHTML = `
    <svg viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg" style="width:28px;height:28px">
      <path fill-rule="evenodd" clip-rule="evenodd" d="M16 0C7.164 0 0 7.164 0 16c0 2.84.74 5.55 2.13 7.94L.7 29.3l5.46-1.43A15.96 15.96 0 0016 32c8.836 0 16-7.164 16-16S24.836 0 16 0zm8.5 22.6c-.3.84-1.48 1.54-2.42 1.74-.64.14-1.48.2-2.38-.14-.54-.2-1.22-.48-2.1-.94-3.66-1.92-6.06-5.7-6.24-5.96-.2-.26-1.5-2-1.5-3.8 0-1.8.94-2.68 1.28-3.04.34-.36.74-.46.98-.46.24 0 .48 0 .7.02.22.02.52-.08.82.62.3.7 1.02 2.42 1.12 2.6.08.18.14.4.04.64-.1.24-.18.36-.36.56-.18.2-.36.36-.52.58-.18.2-.36.42-.16.82.2.4.9 1.48 1.92 2.4 1.32 1.18 2.44 1.54 2.78 1.72.34.18.54.14.74-.1.2-.24.84-.98 1.06-1.32.22-.34.44-.28.74-.16.3.12 1.9.9 2.22 1.06.32.16.54.24.62.38.08.14.08.8-.22 1.58z" fill="white"/>
    </svg>
  `
  Object.assign(btn.style, {
    position:'fixed', bottom:'1.5rem', right:'1.5rem', zIndex:'9997',
    width:'56px', height:'56px', borderRadius:'50%',
    background:'linear-gradient(135deg,#25D366,#128C7E)',
    display:'flex', alignItems:'center', justifyContent:'center',
    boxShadow:'0 4px 20px rgba(37,211,102,0.4)',
    cursor:'pointer', transition:'all 0.3s cubic-bezier(0.16,1,0.3,1)',
    animation:'waPulse 2s ease-in-out infinite'
  })
  btn.onmouseenter = function() {
    this.style.transform = 'scale(1.1) rotate(-5deg)'
    this.style.boxShadow = '0 8px 30px rgba(37,211,102,0.5)'
  }
  btn.onmouseleave = function() {
    this.style.transform = 'scale(1) rotate(0deg)'
    this.style.boxShadow = '0 4px 20px rgba(37,211,102,0.4)'
  }
  document.body.appendChild(btn)
}
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initWhatsApp)
} else {
  initWhatsApp()
}

const style = document.createElement('style')
style.textContent = `
  @keyframes waPulse {
    0%, 100% { box-shadow: 0 4px 20px rgba(37,211,102,0.4); }
    50% { box-shadow: 0 4px 30px rgba(37,211,102,0.7); }
  }
`
document.head.appendChild(style)
