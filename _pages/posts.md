---
layout: page
title: Posts
permalink: /posts
description: Posts from Jonathan Frei, with longer excerpts.
pagination:
  enabled: false
---

{% include feed-filter.html %}

<ul class="post-list stream-list">
  {% assign items = page.stream_items %}
  {% for post in items %}
    <li>
      {% include post-entry.html entry=post %}
    </li>
  {% endfor %}
</ul>

{% if items.size == 0 %}
<p>No posts published yet.</p>
{% endif %}

{% include pagination.html %}
