// Replace your initSidebar() function in firebase.js with this:

function initSidebar() {
  const sidebar   = document.getElementById("sidebarEl");
  const overlay   = document.getElementById("sidebarOverlay");
  const toggleBtn = document.getElementById("sidebarToggle");

  // Restore collapsed state on desktop
  const collapsed = localStorage.getItem("sidebarCollapsed") === "1";
  if (collapsed && window.innerWidth > 768) {
    sidebar?.classList.add("collapsed");
    document.body.classList.add("sidebar-collapsed");
  }

  toggleBtn?.addEventListener("click", () => {
    if (window.innerWidth <= 768) {
      const open = sidebar?.classList.toggle("mobile-open");
      overlay?.classList.toggle("visible", open);
    } else {
      const isCollapsed = sidebar?.classList.toggle("collapsed");
      // Keep body class in sync so CSS margin selector works
      document.body.classList.toggle("sidebar-collapsed", isCollapsed);
      localStorage.setItem("sidebarCollapsed", isCollapsed ? "1" : "0");
    }
  });

  overlay?.addEventListener("click", () => {
    sidebar?.classList.remove("mobile-open");
    overlay?.classList.remove("visible");
  });

  // Active nav link
  const currentFile = window.location.pathname.split("/").pop() || "index.html";
  document.querySelectorAll(".nav-link[data-page]").forEach(a => {
    a.classList.toggle("active", a.dataset.page === currentFile);
  });
}