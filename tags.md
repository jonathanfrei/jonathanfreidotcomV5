---
layout: page
title: Tags
permalink: /tags/
---

<ul class="tags">
  {% assign sorted_tags = site.tags | sort %}
  {% for tag in sorted_tags %}
    {% assign tag_name = tag[0] %}
    {% assign tag_posts = tag[1] %}
    <li>
      <a class="tag" href="{{ '/tags/' | relative_url }}{{ tag_name | slugify }}/">{{ tag_name }}</a>
      <span class="post-meta">({{ tag_posts.size }})</span>
    </li>
  {% endfor %}
</ul>

{% if site.tags.size == 0 %}
<p>No tags yet.</p>
{% endif %}
