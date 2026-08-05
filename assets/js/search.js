/* Minimal client-side search for jonathanfrei.com */
(function () {
  var input = document.getElementById("search-input");
  var results = document.getElementById("search-results");
  if (!input || !results) return;

  var index = [];
  var indexReady = false;

  function resolveIndexUrl() {
    var base = typeof window.siteBaseurl === "string" ? window.siteBaseurl : "";
    if (base === "/") base = "";
    if (base) return base + "/search.json";

    // Fallback: derive from this script's path when baseurl was not injected
    var scripts = document.getElementsByTagName("script");
    for (var i = 0; i < scripts.length; i++) {
      var src = scripts[i].src || "";
      var marker = "/assets/js/search.js";
      var pos = src.indexOf(marker);
      if (pos !== -1) {
        return src.slice(0, pos) + "/search.json";
      }
    }
    return "/search.json";
  }

  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&")
      .replace(/</g, "<")
      .replace(/>/g, ">")
      .replace(/"/g, """);
  }

  function render(items) {
    if (!items.length) {
      results.innerHTML = "<p class=\"post-meta\">No matching posts.</p>";
      return;
    }
    var html = "<ul class=\"post-list\">";
    for (var i = 0; i < items.length; i++) {
      var p = items[i];
      html +=
        "<li>" +
        "<a href=\"" +
        escapeHtml(p.url) +
        "\">" +
        escapeHtml(p.title) +
        "</a>" +
        "<div class=\"post-meta\">" +
        escapeHtml(p.date || "") +
        "</div>" +
        "<p class=\"mt-2 mb-0\">" +
        escapeHtml(p.excerpt || "") +
        "</p>" +
        "</li>";
    }
    html += "</ul>";
    results.innerHTML = html;
  }

  function runSearch() {
    if (!indexReady) return;
    var q = input.value.trim().toLowerCase();
    if (q.length < 2) {
      results.innerHTML = "";
      return;
    }
    var matches = index.filter(function (p) {
      var hay =
        (p.title || "") +
        " " +
        (p.excerpt || "") +
        " " +
        (Array.isArray(p.tags) ? p.tags.join(" ") : "");
      return hay.toLowerCase().indexOf(q) !== -1;
    });
    render(matches);
  }

  fetch(resolveIndexUrl())
    .then(function (r) {
      if (!r.ok) throw new Error("HTTP " + r.status);
      return r.json();
    })
    .then(function (data) {
      index = data || [];
      indexReady = true;
      runSearch();
    })
    .catch(function () {
      results.innerHTML = "<p class=\"post-meta\">Search index unavailable.</p>";
    });

  input.addEventListener("input", runSearch);
})();
