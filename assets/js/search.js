/* Minimal client-side search for jonathanfrei.com */
(function () {
  const input = document.getElementById("search-input");
  const results = document.getElementById("search-results");
  if (!input || !results) return;

  let index = [];

  fetch("{{ '/search.json' | relative_url }}".replace(/\{\{.*?\}\}/, "/search.json"))
    .then((r) => r.json())
    .then((data) => {
      index = data;
    })
    .catch(() => {
      results.innerHTML = "<p>Search index unavailable.</p>";
    });

  // Note: the relative_url above is a placeholder; actual path is injected at build if needed.
  // For pure static we hardcode the path relative to site root.
  fetch("/search.json")
    .then((r) => r.json())
    .then((data) => {
      index = data;
    })
    .catch(() => {});

  function render(items) {
    if (!items.length) {
      results.innerHTML = "<p class=\"post-meta\">No matching posts.</p>";
      return;
    }
    results.innerHTML =
      "<ul class=\"post-list\">" +
      items
        .map(
          (p) =>
            `<li>
              <a href="${p.url}">${escapeHtml(p.title)}</a>
              <div class="post-meta">${p.date}</div>
              <p class="mt-2 mb-0">${escapeHtml(p.excerpt || "")}</p>
            </li>`
        )
        .join("") +
      "</ul>";
  }

  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&")
      .replace(/</g, "<")
      .replace(/>/g, ">")
      .replace(/"/g, """);
  }

  input.addEventListener("input", () => {
    const q = input.value.trim().toLowerCase();
    if (q.length < 2) {
      results.innerHTML = "";
      return;
    }
    const matches = index.filter((p) => {
      const hay =
        (p.title || "") +
        " " +
        (p.excerpt || "") +
        " " +
        (p.tags || []).join(" ");
      return hay.toLowerCase().includes(q);
    });
    render(matches);
  });
})();
