---
layout: page
title: Links
permalink: /links
description: Links, notes, and things worth reading from Jonathan Frei.
pagination:
  enabled: true
  collection: links
  category: ""
  tag: ""
---

{% assign items = paginator.posts | default: site.links %}
{% if items.size == 0 %}
<p>No links published yet.</p>
{% else %}
  {% assign links_by_year = items | group_by_exp: "item", "item.date | date: '%Y'" %}
  {% for year_group in links_by_year %}
  <section class="links-year">
    <h2><a href="{{ '/links/' | append: year_group.name | relative_url }}">{{ year_group.name }}</a></h2>
    <ul class="post-list link-list">
      {% for entry in year_group.items %}
      <li>{% include link-entry.html entry=entry %}</li>
      {% endfor %}
    </ul>
  </section>
  {% endfor %}
{% endif %}

{% include pagination.html %}
