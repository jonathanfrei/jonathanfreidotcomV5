# frozen_string_literal: true

# Treat Markdown under _pages/ as root-level site pages (issue #161).
#
#   _pages/about.md                 → /about
#   _pages/services/service1.md     → /services/service1
#
# Explicit front-matter `permalink:` still wins. Directory is listed under
# `include:` in _config.yml so Jekyll reads underscore-prefixed paths.
module Jekyll
  module PagesDir
    ROOT = "_pages/"

    module_function

    def apply_permalink!(page)
      rel = page.relative_path.to_s.tr("\\", "/")
      return unless rel.start_with?(ROOT)

      # Keep author-supplied permalinks (about.md already has /about, etc.)
      return if page.data["permalink"] && !page.data["permalink"].to_s.empty?

      slug_path = rel.sub(/\A#{Regexp.escape(ROOT)}/, "").sub(/\.[^\/.]+\z/, "")
      page.data["permalink"] = "/#{slug_path}".gsub(%r{/+}, "/")
    end
  end
end

Jekyll::Hooks.register :pages, :post_init do |page|
  Jekyll::PagesDir.apply_permalink!(page)
end
