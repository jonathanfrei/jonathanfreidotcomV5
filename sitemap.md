---
layout: page
title: Sitemap
permalink: /sitemap
description: Hierarchical map of pages, sections, tags, and recent posts on jonathanfrei.com.
---

<p class="post-meta sitemap-lead">A clean, hierarchical map of this site. Machine-readable XML lives at <a href="{{ '/sitemap.xml' | relative_url }}">/sitemap.xml</a>.</p>

<nav class="site-map" aria-label="Site map">
  <ul class="site-map__tree">
    <li>
      <a href="{{ '/' | relative_url }}">Home</a>
    </li>
    <li>
      <a href="{{ '/blog' | relative_url }}">Blog</a>
      {% if site.posts.size > 0 %}
      <ul>
        {% assign posts_by_year = site.posts | group_by_exp: "post", "post.date | date: '%Y'" %}
        {% for year_group in posts_by_year %}
        <li>
          <span class="site-map__heading">{{ year_group.name }}</span>
          <ul>
            {% for post in year_group.items %}
            <li>
              <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
              <span class="post-meta">{{ post.date | date: "%b %-d" }}</span>
            </li>
            {% endfor %}
          </ul>
        </li>
        {% endfor %}
      </ul>
      {% endif %}
    </li>
    <li>
      <a href="{{ '/archive' | relative_url }}">Archive</a>
      <ul>
        <li><a href="{{ '/search' | relative_url }}">Search</a></li>
      </ul>
    </li>
    <li>
      <a href="{{ '/tags' | relative_url }}">Tags</a>
      {% if site.tags.size > 0 %}
      <ul class="site-map__chips">
        {% assign tag_names = site.tags | sort %}
        {% for tag in tag_names %}
          {% assign tag_name = tag[0] | append: "" %}
          <li><a class="tag" href="{{ '/tags/' | relative_url }}{{ tag_name | slugify }}">{{ tag_name }}</a></li>
        {% endfor %}
      </ul>
      {% endif %}
    </li>
    <li>
      <a href="{{ '/categories' | relative_url }}">Categories</a>
      {% if site.categories.size > 0 %}
      <ul class="site-map__chips">
        {% assign cat_names = site.categories | sort %}
        {% for cat in cat_names %}
          {% assign cat_name = cat[0] | append: "" %}
          <li><a class="tag" href="{{ '/categories/' | relative_url }}{{ cat_name | slugify }}">{{ cat_name }}</a></li>
        {% endfor %}
      </ul>
      {% endif %}
    </li>
    <li>
      <a href="{{ '/about' | relative_url }}">About</a>
    </li>
    <li>
      <span class="site-map__heading">Editorial</span>
      <ul>
        <li><a href="{{ '/editorial/invisible-engine' | relative_url }}">The Invisible Engine</a></li>
        <li><a href="{{ '/editorial/design-system' | relative_url }}">Editorial design system</a></li>
        <li><a href="{{ '/editorial/spacex-earnings' | relative_url }}">SpaceX earnings</a></li>
        <li><a href="{{ '/editorial/mainframe-history' | relative_url }}">Mainframe history</a></li>
        <li><a href="{{ '/editorial/lepanto' | relative_url }}">Lepanto</a></li>
        <li><a href="{{ '/editorial/robot-vacuum' | relative_url }}">Robot vacuum</a></li>
      </ul>
    </li>
    <li>
      <a href="{{ '/typography' | relative_url }}">Typography specimen</a>
    </li>
    <li>
      <a href="{{ '/feed.xml' | relative_url }}">RSS feed</a>
    </li>
  </ul>
</nav>

<style>
.sitemap-lead {
  margin-bottom: var(--space-6);
}
.site-map__tree {
  list-style: none;
  padding-left: 0;
  margin: 0;
  font-family: var(--font-ui);
}
.site-map__tree > li {
  margin-bottom: var(--space-4);
}
.site-map__tree > li > a,
.site-map__heading {
  font-weight: 600;
  color: var(--color-fg);
  text-decoration: none;
}
.site-map__tree > li > a:hover,
.site-map__tree > li > a:focus-visible {
  color: var(--color-accent);
  text-decoration: underline;
}
.site-map__tree ul {
  list-style: none;
  padding-left: var(--space-4);
  margin: var(--space-2) 0 0;
  border-left: 1px solid var(--color-border);
}
.site-map__tree ul li {
  margin: 0.35em 0;
}
.site-map__tree ul a {
  text-decoration: none;
}
.site-map__tree ul a:hover,
.site-map__tree ul a:focus-visible {
  text-decoration: underline;
}
.site-map__chips {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  padding-left: var(--space-4) !important;
  border-left: 1px solid var(--color-border);
}
.site-map__chips li {
  margin: 0 !important;
}
</style>
