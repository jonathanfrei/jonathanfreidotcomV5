---
layout: page
title: Posts
permalink: /posts
description: Posts from Jonathan Frei, with longer excerpts.
pagination:
  enabled: true
  collection: posts
  category: ""
  tag: ""
---

{% include feed-filter.html %}

<ul class="post-list stream-list">
  {% for post in paginator.posts %}
    <li>
      {% include post-entry.html entry=post excerpt=true %}
    </li>
  {% endfor %}
</ul>

{% if paginator.posts.size == 0 %}
<p>No posts published yet.</p>
{% endif %}

{% include pagination.html %}
