---
layout: page
title: Search
permalink: /search/
---

<label for="search-input" class="sr-only">Search posts</label>
<input
  type="search"
  id="search-input"
  placeholder="Search posts…"
  autocomplete="off"
  style="width:100%; max-width:20rem; padding:0.5rem 0.75rem; font:inherit; border:1px solid var(--color-border); border-radius:var(--radius); background:var(--color-bg); color:var(--color-fg);"
>

<div id="search-results" class="mt-6" aria-live="polite"></div>

<script>
  window.siteBaseurl = {{ site.baseurl | jsonify }};
</script>
<script src="{{ '/assets/js/search.js' | relative_url }}" defer></script>
