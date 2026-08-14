---
layout: page
title: Blog
permalink: /blog
description: Posts and links from Jonathan Frei.
pagination:
  enabled: true
---

{% include feed-filter.html %}

<ul class="post-list stream-list">
  {% for post in paginator.posts %}
    <li>
      {% if post.layout == 'link' %}
        {% include link-entry.html entry=post %}
      {% else %}
        {% include post-entry.html entry=post %}
      {% endif %}
    </li>
  {% endfor %}
</ul>

{% if paginator.posts.size == 0 %}
<p>No posts or links published yet.</p>
{% endif %}

{% include pagination.html %}
