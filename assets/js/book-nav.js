(function () {
  var panel = document.getElementById("book-nav-panel");
  if (!panel) return;

  var toolbar = document.getElementById("book-toolbar");
  var mount = document.getElementById("book-toc-mount");
  var overlay = mount || panel.querySelector(".book-toc--panel");
  var backdrop = document.getElementById("book-toc-backdrop");
  var header = document.querySelector(".site-header");
  var tocPromise = null;

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

  function syncStickyOffset() {
    if (!toolbar) return;
    var extra = 12;
    var height = Math.ceil(toolbar.getBoundingClientRect().height) + extra;
    document.documentElement.style.setProperty("--book-sticky-offset", height + "px");
  }

  function setOpen(open) {
    panel.open = !!open;
  }

  function syncOpenClass() {
    document.documentElement.classList.toggle("book-nav-open", panel.open);
    if (backdrop) backdrop.hidden = !panel.open;
    if (panel.open) {
      layoutOverlay();
      loadToc();
    }
  }

  function pathOf(href) {
    try {
      var u = new URL(href, window.location.origin);
      var path = u.pathname.replace(/\/+$/, "");
      return path || "/";
    } catch (e) {
      return String(href || "").replace(/\/+$/, "") || "/";
    }
  }

  function escapeHtml(str) {
    var el = document.createElement("span");
    el.textContent = String(str == null ? "" : str);
    return el.innerHTML;
  }

  function labelHtml(item, withNum) {
    var html = "";
    if (withNum && item.num) {
      html += '<span class="book-toc__num">' + escapeHtml(item.num) + "</span> ";
    }
    html += escapeHtml(item.title || "");
    return html;
  }

  function isCurrent(item, currentPath) {
    return pathOf(item.url) === currentPath;
  }

  function chapterContains(item, currentPath) {
    if (isCurrent(item, currentPath)) return true;
    var kids = item.children || [];
    for (var i = 0; i < kids.length; i++) {
      if (isCurrent(kids[i], currentPath)) return true;
    }
    return false;
  }

  function itemLink(item, currentPath, withNum) {
    var current = isCurrent(item, currentPath);
    return (
      '<a href="' +
      escapeHtml(item.url) +
      '"' +
      (current ? ' aria-current="page"' : "") +
      ">" +
      labelHtml(item, withNum) +
      "</a>"
    );
  }

  function renderList(items, currentPath) {
    var html = '<ol class="book-toc__list">';
    (items || []).forEach(function (item) {
      var kids = item.children || [];
      if (kids.length) {
        html +=
          '<li><details class="book-toc__chapter" data-chapter="' +
          escapeHtml(item.slug) +
          '"' +
          (chapterContains(item, currentPath) ? " open" : "") +
          "><summary>" +
          labelHtml(item, true) +
          "</summary><ol><li>" +
          itemLink(item, currentPath, false) +
          "</li>";
        kids.forEach(function (child) {
          html += "<li>" + itemLink(child, currentPath, true) + "</li>";
        });
        html += "</ol></details></li>";
      } else {
        html += "<li>" + itemLink(item, currentPath, true) + "</li>";
      }
    });
    html += "</ol>";
    return html;
  }

  function tocSrc() {
    return mount ? mount.getAttribute("data-toc-src") : "";
  }

  function currentPath() {
    var raw = mount ? mount.getAttribute("data-current") : "";
    return pathOf(raw || window.location.pathname);
  }

  function loadToc() {
    if (!mount) return Promise.resolve();
    if (mount.getAttribute("data-loaded") === "true") return Promise.resolve();
    if (tocPromise) return tocPromise;

    var src = tocSrc();
    if (!src) {
      mount.innerHTML = '<p class="book-toc__status">Contents unavailable.</p>';
      return Promise.resolve();
    }

    tocPromise = fetch(src, { credentials: "same-origin" })
      .then(function (res) {
        if (!res.ok) throw new Error("toc.json " + res.status);
        return res.json();
      })
      .then(function (data) {
        mount.innerHTML = renderList(data.items || [], currentPath());
        mount.setAttribute("data-loaded", "true");
      })
      .catch(function () {
        tocPromise = null;
        mount.innerHTML =
          '<p class="book-toc__status">Couldn’t load contents.</p>';
      });
    return tocPromise;
  }

  panel.addEventListener("toggle", syncOpenClass);
  window.addEventListener("resize", function () {
    layoutOverlay();
    syncStickyOffset();
  });
  if (typeof ResizeObserver !== "undefined" && toolbar) {
    new ResizeObserver(syncStickyOffset).observe(toolbar);
  }
  syncStickyOffset();

  panel.addEventListener("pointerenter", function () {
    loadToc();
  });
  var summary = panel.querySelector("summary");
  if (summary) {
    summary.addEventListener("focus", function () {
      loadToc();
    });
  }

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && panel.open) {
      setOpen(false);
      if (summary) summary.focus();
    }
  });

  if (backdrop) {
    backdrop.addEventListener("click", function () {
      setOpen(false);
    });
  }
})();
