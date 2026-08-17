---
layout: page
title: Categories
permalink: /categories
---
{% include search-ui.html %}
{%- assign archive_categories = site.data.archive_categories -%}
{%- if archive_categories.size == 0 -%}
<p>No categories yet.</p>
{%- else -%}
<ul class="tags" id="categories-list">
{%- comment -%}
  Precomputed in _plugins/site_index.rb. Chips link to /categories?category=name.
{%- endcomment -%}
{%- for cat in archive_categories -%}
  <li data-name="{{ cat.name | downcase | escape }}" data-count="{{ cat.count }}">
    <a class="tag" href="{{ '/categories' | relative_url }}?category={{ cat.name | url_encode }}">{{ cat.name }}</a>
    <span class="post-meta">({{ cat.count }})</span>
  </li>
{%- endfor -%}
</ul>
{%- endif -%}
