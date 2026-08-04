---
layout: default
title: Home
---

# Hello

Hi, I’m **Jonathan Frei**.

This is version 5 of my personal site. Earlier versions lived on Blogger, Tumblr, self-hosted WordPress, and a previous static setup. The current site is built with Jekyll, deployed via GitHub Actions, and served through Cloudflare.

You can reach me at [hi&#64;jonathanfrei&#46;com](mailto:hi&#64;jonathanfrei&#46;com).

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
