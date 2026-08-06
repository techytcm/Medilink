/* MediLink — shared client utilities (Dark Mode Only Edition) */
(function () {
  const root = document.documentElement;

  // ----- Force Dark Mode -----
  root.classList.add('dark');
  
  // ----- Mobile sidebar -----
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('sidebar-overlay');
  const menuBtn = document.getElementById('menu-btn');
  
  function openSidebar() {
    if (sidebar) sidebar.classList.remove('-translate-x-full');
    if (overlay) overlay.classList.remove('hidden');
    document.body.classList.add('sidebar-open');
  }
  
  function closeSidebar() {
    if (sidebar) sidebar.classList.add('-translate-x-full');
    if (overlay) overlay.classList.add('hidden');
    document.body.classList.remove('sidebar-open');
  }
  
  if (menuBtn) menuBtn.addEventListener('click', openSidebar);
  if (overlay) overlay.addEventListener('click', closeSidebar);

  // ----- Auto-dismiss flash messages -----
  setTimeout(() => {
    document.querySelectorAll('.flash-msg').forEach(el => {
      el.style.opacity = '0';
      el.style.transform = 'translateY(-8px)';
      setTimeout(() => el.remove(), 250);
    });
  }, 5000);

  // ----- Preloader Logic -----
  window.addEventListener('load', function() {
    const preloader = document.getElementById('preloader');
    
    // If it's the first time loading in this tab session
    if (!sessionStorage.getItem('medilink_loaded')) {
      // Mark as seen
      sessionStorage.setItem('medilink_loaded', 'true');
      
      // Wait 3 seconds (3000ms) before fading out
      setTimeout(function() {
        if (preloader) {
          preloader.classList.add('preloader-hidden');
        }
      }, 3000);
    } else {
      // If they already saw it, hide it instantly just in case
      if (preloader) {
        preloader.classList.add('preloader-hidden');
      }
    }
  });
})();