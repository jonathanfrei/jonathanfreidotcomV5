(function () {
  var panel = document.getElementById("book-nav-panel");
  if (!panel) return;

  var toolbar = document.getElementById("book-toolbar");
  var overlay = panel.querySelector(".book-toc--panel");
  var backdrop = document.getElementById("book-toc-backdrop");
  var header = document.querySelector(".site-header");

  function overlayTop() {
    if (toolbar) {
      var t = toolbar.getBoundingClientRect();
      if (t.bottom > 0 && t.bottom < window.innerHeight) return t.bottom;
    }
    if (header) {
      var h = header.getBoundingClientRect();
      if (h.bottom > 0) return Math.max(0, h.bottom);
    }
    return 0;
  }

  function layoutOverlay() {
    if (!overlay || !panel.open) return;
    document.documentElement.style.setProperty("--book-overlay-top", overlayTop() + "px");
  }

  function setOpen(open) {
    panel.open = !!open;
  }

  function syncOpenClass() {
    document.documentElement.classList.toggle("book-nav-open", panel.open);
    if (backdrop) backdrop.hidden = !panel.open;
    if (panel.open) layoutOverlay();
  }

  panel.addEventListener("toggle", syncOpenClass);
  window.addEventListener("resize", layoutOverlay);

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && panel.open) {
      setOpen(false);
      var summary = panel.querySelector("summary");
      if (summary) summary.focus();
    }
  });

  if (backdrop) {
    backdrop.addEventListener("click", function () { setOpen(false); });
  }
})();
