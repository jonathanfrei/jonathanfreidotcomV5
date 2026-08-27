/* Client-side search for jonathanfrei.com (#209, #211, #219)
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
    // search.json is generated and stays at /search.json. Do not derive it
    // from the search.js URL. ?v= is the build time so a Cloudflare Cache
    // Everything HIT cannot keep a pre-deploy index (the #214 categories miss).
    var path = (base || "") + "/search.json";
    var rev = window.searchIndexRev == null ? "" : String(window.searchIndexRev);
    return rev ? path + "?v=" + encodeURIComponent(rev) : path;
  }

  // Avoid HTML entity literals in source (GitHub content API can strip them).
  function escapeHtml(str) {
    var el = document.createElement("span");
    el.textContent = String(str);
    return el.innerHTML;
  }

  function siteBase() {
    var base = typeof window.siteBaseurl === "string" ? window.siteBaseurl : "";
    if (base === "/") base = "";
    return base || "";
  }

  function formatLongDate(iso) {
    var parts = String(iso || "").split("-");
    if (parts.length < 3) return iso || "";
    var months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    var month = months[parseInt(parts[1], 10) - 1];
    var day = parseInt(parts[2], 10);
    if (!month || !day) return iso || "";
    return month + " " + day + ", " + parts[0];
  }

  function tagHref(tag) {
    return siteBase() + "/tags?tag=" + encodeURIComponent(tag);
  }

  function isSafeSrc(src) {
    if (!src) return false;
    if (/^https?:\/\//i.test(src)) return true;
    if (src.charAt(0) === "/" && src.charAt(1) !== "/") return true;
    return false;
  }

  function isGifSrc(src) {
    return /\.gif(?:[?#]|$)/i.test(String(src || ""));
  }

  function displayImgSrc(src) {
    if (!src || isGifSrc(src)) return src;
    if (/^https?:\/\/(?:wsrv\.nl|images\.weserv\.nl)\//i.test(src)) return src;
    if (!/^https?:\/\//i.test(src)) return src;
    var inner;
    if (/^https:\/\/(?:[^/]+\.)?(?:springernature\.com|springer\.com)\//i.test(src)) {
      inner = src.replace(/^https:\/\//i, "ssl:");
    } else {
      inner = src.replace(/^https?:\/\//i, "");
    }
    return (
      "https://wsrv.nl/?url=" +
      encodeURIComponent(inner) +
      "&w=768&output=webp&q=85&we"
    );
  }

  function renderTags(tags) {
    if (!Array.isArray(tags) || !tags.length) return "";
    var html = '<div class="post-tags"><ul class="post-tags__list">';
    var count = 0;
    for (var i = 0; i < tags.length; i++) {
      var t = String(tags[i] || "").trim();
      if (!t) continue;
      html +=
        '<li><a href="' +
        escapeHtml(tagHref(t)) +
        '" class="tag">' +
        escapeHtml(t) +
        "</a></li>";
      count += 1;
    }
    html += "</ul></div>";
    return count ? html : "";
  }

  function renderImg(img, permalink) {
    if (!img) return "";
    var src = typeof img === "string" ? img : img.src;
    var alt = typeof img === "object" && img ? img.alt : "";
    if (!isSafeSrc(src) || isGifSrc(src)) return "";
    var display = displayImgSrc(src);
    var tag =
      '<img src="' +
      escapeHtml(display) +
      '" alt="' +
      escapeHtml(alt || "") +
      '" loading="lazy" decoding="async"';
    if (display !== src) {
      tag += ' data-full-src="' + escapeHtml(src) + '"';
    }
    tag += ">";
    if (permalink) {
      return (
        '<p><a href="' + escapeHtml(permalink) + '">' + tag + "</a></p>"
      );
    }
    return "<p>" + tag + "</p>";
  }

  function renderDate(p) {
    var url = p.url || "";
    var label = p.date_label || formatLongDate(p.date) || p.date || "";
    return (
      '<a class="post-meta__date" href="' +
      escapeHtml(url) +
      '"><time datetime="' +
      escapeHtml(p.date || "") +
      '">' +
      escapeHtml(label) +
      "</time></a>"
    );
  }

  function renderEntry(p) {
    var url = p.url || "";
    var tags = renderTags(p.tags);
    var excerpt = p.excerpt ? "<p>" + escapeHtml(p.excerpt) + "</p>" : "";
    var img = renderImg(p.img, url);
    var body = excerpt + img;
    if (p.kind === "link") {
      return (
        '<li><div class="link-entry">' +
        '<p class="post-meta link-entry__meta">' +
        renderDate(p) +
        "</p>" +
        (excerpt ? '<div class="link-entry__body">' + excerpt + "</div>" : "") +
        tags +
        (img ? '<div class="prose">' + img + "</div>" : "") +
        "</div></li>"
      );
    }
    return (
      '<li><article class="stream-post">' +
      '<h2 class="stream-post__title"><a href="' +
      escapeHtml(url) +
      '">' +
      escapeHtml(p.title || "") +
      "</a></h2>" +
      '<p class="post-meta stream-post__meta">' +
      renderDate(p) +
      "</p>" +
      tags +
      (body ? '<div class="prose stream-post__excerpt">' + body + "</div>" : "") +
      '<p class="read-more"><a href="' +
      escapeHtml(url) +
      '">Read more</a></p>' +
      "</article></li>"
    );
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
    html += '<ul class="post-list stream-list">';
    for (var i = 0; i < items.length; i++) {
      html += renderEntry(items[i]);
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
