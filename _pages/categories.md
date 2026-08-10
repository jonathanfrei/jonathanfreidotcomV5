---
layout: page
title: Categories
permalink: /categories
---
{%- if site.categories.size == 0 -%}
<p>No categories yet.</p>
{%- else -%}
<ul class="tags" id="categories-list">
{%- assign max_count = 0 -%}
{%- for cat in site.categories -%}
  {%- if cat[1].size > max_count -%}
    {%- assign max_count = cat[1].size -%}
  {%- endif -%}
{%- endfor -%}
{%- for count in (1..max_count) reversed -%}
  {%- for cat in site.categories -%}
    {%- assign cat_name = cat[0] | append: "" -%}
    {%- assign cat_posts = cat[1] -%}
    {%- if cat_posts.size == count -%}
  <li data-name="{{ cat_name | downcase | escape }}" data-count="{{ cat_posts.size }}">
    <a class="tag" href="{{ '/categories/' | relative_url }}{{ cat_name | slugify }}">{{ cat_name }}</a>
    <span class="post-meta">({{ cat_posts.size }})</span>
  </li>
    {%- endif -%}
  {%- endfor -%}
{%- endfor -%}
</ul>
{%- endif -%}
