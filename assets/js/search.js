/* Minimal client-side search for jonathanfrei.com */
(function () {
  const input = document.getElementById("search-input");
  const results = document.getElementById("search-results");
  if (!input || !results) return;

  let index = [];

  fetch("/search.json")
    .then(function (r) {
      return r.json();
    })
    .then(function (data) {
      index = data || [];
    })
    .catch(function () {
      results.innerHTML = "<p class=\"post-meta\">Search index unavailable.</p>";
    });

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
        '<a href="' +
        escapeHtml(p.url) +
        '">' +
        escapeHtml(p.title) +
        "</a>" +
        '<div class="post-meta">' +
        escapeHtml(p.date || "") +
        "</div>" +
        '<p class="mt-2 mb-0">' +
        escapeHtml(p.excerpt || "") +
        "</p>" +
        "</li>";
    }
    html += "</ul>";
    results.innerHTML = html;
  }

  input.addEventListener("input", function () {
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
  });
})();
