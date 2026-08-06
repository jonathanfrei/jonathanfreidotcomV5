---
layout: page
title: Archive
permalink: /archive/
---

<style>
.archive-list {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2) var(--space-4);
  list-style: none;
  padding: 0;
  margin: var(--space-4) 0 0;
  font-family: var(--font-ui);
  font-size: var(--type-sm);
}
.archive-list li {
  display: inline-block;
  margin: 0;
  padding: 0;
  border: 0;
}
.archive-list a {
  text-decoration: none;
  color: var(--color-fg);
}
.archive-list a:hover,
.archive-list a:focus-visible {
  color: var(--color-accent);
  text-decoration: underline;
}
.search-ui {
  margin-bottom: var(--space-8);
}
</style>

{% include search-ui.html %}

{% include archive-list.html %}
