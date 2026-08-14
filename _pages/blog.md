---
layout: page
title: Blog
permalink: /blog
description: Posts and links from Jonathan Frei.
pagination:
  enabled: false
---

{% include feed-filter.html %}

<ul class="post-list stream-list">
  {% assign items = page.stream_items | default: site.data.site_stream %}
  {% for item in items %}
    <li>
      {% if item.kind == 'link' %}
        {% include link-entry.html entry=item %}
      {% else %}
        {% include post-entry.html entry=item %}
      {% endif %}
    </li>
  {% endfor %}
</ul>

{% if items.size == 0 %}
<p>No posts or links published yet.</p>
{% endif %}

{% include pagination.html %}
