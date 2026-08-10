---
layout: page
title: Blog
permalink: /blog
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
        {%- if post.tags.size > 0 -%}
          ·
          <span class="tag-row">
          {%- for tag in post.tags -%}
            {% include tag-chip.html tag=tag %}
          {%- endfor -%}
          </span>
        {%- endif -%}
      </div>
      {% if post.excerpt %}
        <p class="excerpt">{{ post.excerpt | strip_html | truncate: 160 }}</p>
      {% endif %}
    </li>
  {% endfor %}
</ul>

{% if paginator.posts.size == 0 %}
<p>No posts published yet.</p>
{% endif %}

{% include pagination.html %}
