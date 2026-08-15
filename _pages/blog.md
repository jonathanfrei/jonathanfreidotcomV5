---
layout: page
title: Blog
permalink: /blog
description: Posts and links from Jonathan Frei.
pagination:
  enabled: false
---

<ul class="post-list stream-list">
  {% assign items = page.stream_items %}
  {% for post in items %}
    <li>
      {% if post.layout == 'link' %}
        {% include link-entry.html entry=post %}
      {% else %}
        {% include post-entry.html entry=post %}
      {% endif %}
    </li>
  {% endfor %}
</ul>

{% if items.size == 0 %}
<p>No posts published yet.</p>
{% endif %}

{% include pagination.html %}
