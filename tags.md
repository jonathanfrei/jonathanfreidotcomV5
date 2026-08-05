---
layout: page
title: Tags
permalink: /tags/
---

{% if site.tags.size == 0 %}
<p>No tags yet.</p>
{% else %}

<p class="tags-sort-controls" role="group" aria-label="Sort tags">
  <button type="button" id="tags-sort-freq" class="tags-sort-btn is-active" aria-pressed="true">By frequency</button>
  <button type="button" id="tags-sort-alpha" class="tags-sort-btn" aria-pressed="false">Alphabetical</button>
</p>

<ul class="tags" id="tags-list">
  {% comment %}
    Default: most-used first. Find max post count, then emit tags in
    descending count order. Coerce keys to strings (normalize_tags plugin
    should already do this; append "" is a safety net).
  {% endcomment %}
  {% assign max_count = 0 %}
  {% for tag in site.tags %}
    {% if tag[1].size > max_count %}
      {% assign max_count = tag[1].size %}
    {% endif %}
  {% endfor %}

  {% for count in (1..max_count) reversed %}
    {% for tag in site.tags %}
      {% assign tag_name = tag[0] | append: "" %}
      {% assign tag_posts = tag[1] %}
      {% if tag_posts.size == count %}
      <li data-name="{{ tag_name | downcase | escape }}" data-count="{{ tag_posts.size }}">
        <a class="tag" href="{{ '/tags/' | relative_url }}{{ tag_name | slugify }}/">{{ tag_name }}</a>
        <span class="post-meta">({{ tag_posts.size }})</span>
      </li>
      {% endif %}
    {% endfor %}
  {% endfor %}
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

{% endif %}
