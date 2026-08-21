# Deprecated Jekyll source

These files are retained for historical reference and excluded from the Jekyll
build. Their original locations are represented by the subdirectories here.

- `_includes/editorial-note.html` was never referenced.
- `_layouts/tag.html` and `_layouts/category.html` became unused when taxonomy
  archives moved to query-driven `/tags` and `/categories` pages.
- `_plugins/limit_tag_autopages.rb` became unnecessary after removing the
  unused `jekyll-paginate-v2` dependency and its disabled AutoPages config.

See issue #266.
