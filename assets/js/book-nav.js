(function () {
  var panel = document.getElementById("book-nav-panel");
  if (!panel) return;

  var book = panel.getAttribute("data-book") || "book";
  var key = "book-nav:" + book;

  function readState() {
    try {
      var raw = localStorage.getItem(key);
      if (!raw) return { panel: false, open: [] };
      var parsed = JSON.parse(raw);
      return {
        panel: !!parsed.panel,
        open: Array.isArray(parsed.open) ? parsed.open : []
      };
    } catch (e) {
      return { panel: false, open: [] };
    }
  }

  function writeState(state) {
    try {
      localStorage.setItem(key, JSON.stringify(state));
    } catch (e) { /* private mode */ }
  }

  function currentOpenChapters() {
    return Array.prototype.map.call(
      panel.querySelectorAll("details.book-toc__chapter[open]"),
      function (el) { return el.getAttribute("data-chapter"); }
    ).filter(Boolean);
  }

  function applyState(state) {
    panel.open = !!state.panel;
    var want = {};
    (state.open || []).forEach(function (slug) { want[slug] = true; });
    panel.querySelectorAll("details.book-toc__chapter").forEach(function (el) {
      var slug = el.getAttribute("data-chapter");
      if (slug && Object.prototype.hasOwnProperty.call(want, slug)) {
        el.open = !!want[slug];
      }
    });
  }

  var state = readState();
  panel.open = !!state.panel;
  if (state.open && state.open.length) {
    applyState(state);
  }

  panel.addEventListener("toggle", function () {
    state.panel = panel.open;
    if (panel.open) state.open = currentOpenChapters();
    writeState(state);
  });

  panel.addEventListener("toggle", function (event) {
    if (event.target === panel) return;
    if (!event.target.classList.contains("book-toc__chapter")) return;
    state.open = currentOpenChapters();
    writeState(state);
  }, true);

  document.querySelectorAll("[data-book-focus-toc]").forEach(function (btn) {
    btn.addEventListener("click", function () {
      panel.open = true;
      state.panel = true;
      writeState(state);
      var summary = panel.querySelector("summary");
      if (summary) summary.focus();
      panel.scrollIntoView({ block: "nearest" });
    });
  });
})();
