---
layout: page
title: Books
permalink: /books
description: Long-form books on jonathanfrei.com.
---

{% assign listed_books = site.books | where_exp: "doc", "doc.is_book_home and doc.book_listed" %}
{% if listed_books.size == 0 %}
<p>Books will appear here.</p>
{% else %}
<ul class="book-catalog">
  {% for book in listed_books %}
  <li>
    <a href="{{ book.url | relative_url }}">{{ book.title }}</a>
    {% if book.description %}
    <p>{{ book.description }}</p>
    {% endif %}
  </li>
  {% endfor %}
</ul>
{% endif %}
