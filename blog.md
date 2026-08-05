---
layout: page
title: Blog
permalink: /blog
---

Short posts and notes.

<ul class="post-list">
  {% for post in site.posts %}
    <li>
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <div class="post-meta">
        <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%B %-d, %Y" }}</time>
        {% if post.tags.size > 0 %}
          ·
          {% for tag in post.tags %}
            <a href="{{ '/tags/' | relative_url }}{{ tag | slugify }}" class="tag">{{ tag }}</a>
          {% endfor %}
        {% endif %}
      </div>
      {% if post.excerpt %}
        <p class="mt-2 mb-0">{{ post.excerpt | strip_html | truncate: 160 }}</p>
      {% endif %}
    </li>
  {% endfor %}
</ul>

{% if site.posts.size == 0 %}
<p>No posts published yet.</p>
{% endif %}
