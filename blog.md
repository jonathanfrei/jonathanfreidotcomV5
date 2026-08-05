---
layout: page
title: Blog
permalink: /blog/
pagination:
  enabled: true
---

Short posts and notes.

<ul class="post-list">
  {% for post in paginator.posts %}
    <li>
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <div class="post-meta">
        <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%B %-d, %Y" }}</time>
        {% if post.tags.size > 0 %}
          ·
          {% for tag in post.tags %}
            {% assign tag_str = tag | append: "" %}
            <a href="{{ '/tags/' | relative_url }}{{ tag_str | slugify }}/" class="tag">{{ tag_str }}</a>
          {% endfor %}
        {% endif %}
      </div>
      {% if post.excerpt %}
        <p class="mt-2 mb-0">{{ post.excerpt | strip_html | truncate: 160 }}</p>
      {% endif %}
    </li>
  {% endfor %}
</ul>

{% if paginator.posts.size == 0 %}
<p>No posts published yet.</p>
{% endif %}

{% include pagination.html %}
