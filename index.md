---
layout: default
title: Home
---

# Hello

This is the personal site of **Jonathan Frei**.

Short posts live on the [blog]({{ '/blog/' | relative_url }}). Longer writing will appear as articles. A portfolio / photo gallery may come later.

## Recent posts

<ul class="post-list">
  {% for post in site.posts limit:5 %}
    <li>
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      <div class="post-meta">
        <time datetime="{{ post.date | date_to_xmlschema }}">{{ post.date | date: "%b %-d, %Y" }}</time>
      </div>
    </li>
  {% endfor %}
</ul>

{% if site.posts.size == 0 %}
<p class="post-meta">No posts yet.</p>
{% endif %}
