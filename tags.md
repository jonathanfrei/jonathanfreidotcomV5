---
layout: page
title: Tags
permalink: /tags/
---

<ul class="tags">
  {% comment %}
    Build a string list of tag names so sort never compares Integer vs String
    keys from site.tags (which raises "comparison of Array with Array failed").
  {% endcomment %}
  {% capture tag_names_csv %}{% for tag in site.tags %}{{ tag[0] | append: "" }}{% unless forloop.last %}|{% endunless %}{% endfor %}{% endcapture %}
  {% assign sorted_tag_names = tag_names_csv | split: "|" | sort %}
  {% for tag_name in sorted_tag_names %}
    {% unless tag_name == "" %}
      {% assign tag_posts = nil %}
      {% for tag in site.tags %}
        {% assign candidate = tag[0] | append: "" %}
        {% if candidate == tag_name %}
          {% assign tag_posts = tag[1] %}
        {% endif %}
      {% endfor %}
      {% if tag_posts %}
      <li>
        <a class="tag" href="{{ '/tags/' | relative_url }}{{ tag_name | slugify }}/">{{ tag_name }}</a>
        <span class="post-meta">({{ tag_posts.size }})</span>
      </li>
      {% endif %}
    {% endunless %}
  {% endfor %}
</ul>

{% if site.tags.size == 0 %}
<p>No tags yet.</p>
{% endif %}
