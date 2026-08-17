/* Client-side search for jonathanfrei.com (#209, #211)
 *
 * URL convention on any page with the search box:
 *   ?q=photography          free-text (title, excerpt, tags)
 *   ?=photography           alias for ?q=
 *   ?tag=photography        tags field only
 *   ?category=links         categories field only
 *   ?title=photography      title field only
 *   ?q=pope&tag=vatican     AND across present fields
 *
 * The search box also accepts field tokens:
 *   tag:photography category:links title:"a phrase"
 *
 * Until the user types, the query string is the source of truth. The input
 * can be empty on first paint (autofill / form restore / deferred script),
 * and must not wipe ?tag= or skip the search.
 */
(function () {
  var input = document.getElementById("search-input");
  var results = document.getElementById("search-results");
  if (!input || !results) return;

  var index = [];
  var indexReady = false;
  var userTyped = false;
  var writingUrl = false;

  function resolveIndexUrl() {
    var base = typeof window.siteBaseurl === "string" ? window.siteBaseurl : "";
    if (base === "/") base = "";
    if (base) return base + "/search.json";

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

  // Avoid HTML entity literals in source (GitHub content API can strip them).
  function escapeHtml(str) {
    var el = document.createElement("span");
    el.textContent = String(str);
    return el.innerHTML;
  }

  function slugify(value) {
    return String(value || "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "");
  }

  function includesFold(hay, needle) {
    return (
      String(hay || "")
        .toLowerCase()
        .indexOf(String(needle || "").toLowerCase()) !== -1
    );
  }

  function quoteIfNeeded(value) {
    if (/[\s:=]/.test(value)) return '"' + value + '"';
    return value;
  }

  function parseParams(search) {
    var params;
    try {
      params = new URLSearchParams(
        search == null ? window.location.search || "" : search
      );
    } catch (e) {
      return { q: "", tag: "", category: "", title: "" };
    }
    var q = (params.get("q") || "").trim();
    var tag = (params.get("tag") || "").trim();
    var category = (params.get("category") || "").trim();
    var title = (params.get("title") || "").trim();
    if (!q) {
      var emptyKey = params.get("");
      if (emptyKey) q = String(emptyKey).trim();
    }
    return { q: q, tag: tag, category: category, title: title };
  }

  function parseInput(raw) {
    var tag = "";
    var category = "";
    var title = "";
    var rest = String(raw || "").replace(
      /(^|\s)(tag|category|title)[:=](?:"([^"]*)"|(\S+))/gi,
      function (_, _lead, field, quoted, bare) {
        var value = (typeof quoted === "string" ? quoted : bare || "").trim();
        field = String(field || "").toLowerCase();
        if (field === "tag") tag = value;
        if (field === "category") category = value;
        if (field === "title") title = value;
        return " ";
      }
    );
    return {
      q: rest.replace(/\s+/g, " ").trim(),
      tag: tag,
      category: category,
      title: title
    };
  }

  function formatInput(state) {
    var parts = [];
    if (state.tag) parts.push("tag:" + quoteIfNeeded(state.tag));
    if (state.category) parts.push("category:" + quoteIfNeeded(state.category));
    if (state.title) parts.push("title:" + quoteIfNeeded(state.title));
    if (state.q) parts.push(state.q);
    return parts.join(" ");
  }

  function describeQuery(state) {
    return formatInput(state);
  }

  function hasActiveQuery(state) {
    return !!(state.tag || state.category || state.title || state.q);
  }

  function canSearch(state) {
    if (state.tag || state.category || state.title) return true;
    return state.q.length >= 2;
  }

  function writeUrl(state) {
    var params = new URLSearchParams();
    if (state.tag) params.set("tag", state.tag);
    if (state.category) params.set("category", state.category);
    if (state.title) params.set("title", state.title);
    if (state.q) params.set("q", state.q);
    var qs = params.toString();
    var path = window.location.pathname || "";
    var hash = window.location.hash || "";
    var next = path + (qs ? "?" + qs : "") + hash;
    var current = path + (window.location.search || "") + hash;
    if (next === current) return;
    if (window.history && window.history.replaceState) {
      writingUrl = true;
      window.history.replaceState(null, "", next);
      writingUrl = false;
    }
  }

  function listMatches(values, query) {
    if (!query) return true;
    if (!Array.isArray(values)) return false;
    var q = query.toLowerCase();
    var qSlug = slugify(query);
    for (var i = 0; i < values.length; i++) {
      var raw = String(values[i] || "");
      var folded = raw.toLowerCase();
      if (folded === q) return true;
      if (slugify(raw) === qSlug) return true;
      if (folded.indexOf(q) !== -1) return true;
    }
    return false;
  }

  function matchEntry(post, state) {
    if (state.tag && !listMatches(post.tags, state.tag)) return false;
    if (state.category && !listMatches(post.categories, state.category)) return false;
    if (state.title && !includesFold(post.title, state.title)) return false;
    if (state.q) {
      var hay =
        (post.title || "") +
        " " +
        (post.excerpt || "") +
        " " +
        (Array.isArray(post.tags) ? post.tags.join(" ") : "") +
        " " +
        (Array.isArray(post.categories) ? post.categories.join(" ") : "");
      if (!includesFold(hay, state.q)) return false;
    }
    return hasActiveQuery(state);
  }

  function setSearching(on) {
    document.documentElement.classList.toggle("has-search-query", !!on);
  }

  function render(items, state) {
    var label = describeQuery(state);
    if (!items.length) {
      results.innerHTML =
        '<p class="post-meta">No matching posts' +
        (label ? " for " + escapeHtml(label) : "") +
        ".</p>";
      return;
    }
    var html =
      '<p class="post-meta">' +
      items.length +
      (items.length === 1 ? " post" : " posts") +
      (label ? " for " + escapeHtml(label) : "") +
      ".</p>";
    html += '<ul class="post-list">';
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

  function stateForSearch() {
    if (!userTyped) return parseParams();
    return parseInput(input.value);
  }

  function seedInput(state) {
    if (userTyped) return;
    var text = hasActiveQuery(state) ? formatInput(state) : "";
    input.value = text;
    try {
      input.defaultValue = text;
    } catch (e) { /* ignore */ }
  }

  function runSearch() {
    var state = stateForSearch();
    seedInput(state);
    setSearching(hasActiveQuery(state));
    if (userTyped) writeUrl(state);
    if (!indexReady) return;
    if (!canSearch(state)) {
      results.innerHTML = "";
      return;
    }
    var matches = index.filter(function (p) {
      return matchEntry(p, state);
    });
    render(matches, state);
  }

  seedInput(parseParams());
  setSearching(hasActiveQuery(parseParams()));

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
      results.innerHTML = '<p class="post-meta">Search index unavailable.</p>';
    });

  input.addEventListener("input", function () {
    userTyped = true;
    runSearch();
  });

  window.addEventListener("pageshow", function () {
    if (writingUrl) return;
    if (!userTyped) seedInput(parseParams());
    runSearch();
  });

  window.addEventListener("popstate", function () {
    if (writingUrl) return;
    userTyped = false;
    seedInput(parseParams());
    runSearch();
  });
})();
