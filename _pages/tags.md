---
layout: page
title: Tags
permalink: /tags
---
{% include search-ui.html %}
<style>
.tags-sort-controls {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin: 0 0 var(--space-4);
  font-family: var(--font-ui);
}
.tags-sort-btn {
  font: inherit;
  font-size: var(--type-sm);
  line-height: 1.3;
  color: var(--color-muted);
  background: transparent;
  border: 1px solid var(--color-border);
  border-radius: var(--radius);
  padding: 0.25em 0.7em;
  cursor: pointer;
}
.tags-sort-btn:hover {
  color: var(--color-accent);
  border-color: var(--color-accent);
}
.tags-sort-btn:focus-visible {
  color: var(--color-accent);
  border-color: var(--color-accent);
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}
.tags-sort-btn.is-active {
  color: var(--color-fg);
  border-color: var(--color-fg);
  background: var(--color-code-bg);
}
</style>
{%- assign archive_tags = site.data.archive_tags -%}
{%- if archive_tags.size == 0 -%}
<p>No tags yet.</p>
{%- else -%}
<p class="tags-sort-controls" role="group" aria-label="Sort tags">
  <button type="button" id="tags-sort-freq" class="tags-sort-btn is-active" aria-pressed="true">By frequency</button>
  <button type="button" id="tags-sort-alpha" class="tags-sort-btn" aria-pressed="false">Alphabetical</button>
</p>
<ul class="tags" id="tags-list">
{%- comment -%}
  Precomputed in _plugins/site_index.rb: tags with 2+ posts, most-used first (#140, #195).
  Chips link to /tags?tag=name instead of /tags/:name (#209).
{%- endcomment -%}
{%- for tag in archive_tags -%}
  <li data-name="{{ tag.name | downcase | escape }}" data-count="{{ tag.count }}">
    <a class="tag" href="{{ '/tags' | relative_url }}?tag={{ tag.name | url_encode }}">{{ tag.name }}</a>
    <span class="post-meta">({{ tag.count }})</span>
  </li>
{%- endfor -%}
</ul>
<script>
(function () {
  var list = document.getElementById("tags-list");
  var btnFreq = document.getElementById("tags-sort-freq");
  var btnAlpha = document.getElementById("tags-sort-alpha");
  if (!list || !btnFreq || !btnAlpha) return;

  function items() {
    return Array.prototype.slice.call(list.querySelectorAll("li"));
  }

  function sortBy(mode) {
    var nodes = items();
    nodes.sort(function (a, b) {
      if (mode === "alpha") {
        return (a.getAttribute("data-name") || "").localeCompare(
          b.getAttribute("data-name") || ""
        );
      }
      var ca = parseInt(a.getAttribute("data-count"), 10) || 0;
      var cb = parseInt(b.getAttribute("data-count"), 10) || 0;
      if (cb !== ca) return cb - ca;
      return (a.getAttribute("data-name") || "").localeCompare(
        b.getAttribute("data-name") || ""
      );
    });
    for (var i = 0; i < nodes.length; i++) {
      list.appendChild(nodes[i]);
    }
  }

  function setActive(mode) {
    var isFreq = mode === "freq";
    btnFreq.classList.toggle("is-active", isFreq);
    btnAlpha.classList.toggle("is-active", !isFreq);
    btnFreq.setAttribute("aria-pressed", isFreq ? "true" : "false");
    btnAlpha.setAttribute("aria-pressed", isFreq ? "false" : "true");
    sortBy(isFreq ? "freq" : "alpha");
  }

  btnFreq.addEventListener("click", function () {
    setActive("freq");
  });
  btnAlpha.addEventListener("click", function () {
    setActive("alpha");
  });
})();
</script>
{%- endif -%}
