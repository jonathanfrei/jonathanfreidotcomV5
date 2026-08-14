---
layout: page
title: Links
permalink: /links
description: Links, notes, and things worth reading from Jonathan Frei.
pagination:
  enabled: false
---

{% include feed-filter.html %}

<ul class="post-list link-list">
  {% assign items = page.stream_items %}
  {% for entry in items %}
    <li>{% include link-entry.html entry=entry %}</li>
  {% endfor %}
</ul>

{% if items.size == 0 %}
<p>No links published yet.</p>
{% endif %}

{% include pagination.html %}
