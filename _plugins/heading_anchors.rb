# frozen_string_literal: true

# Automatic heading permalinks for pages and posts (issue #160).
#
# After each HTML document renders, wrap each H2/H3 in a same-page link and
# expose a hover/focus link icon to the left. Existing heading styles are
# preserved (color/size come from the heading; the anchor is unstyled text).
# Applied to doc.output only so RSS (post.content) stays free of anchors.
#
# Skips headings that already contain a .heading-anchor (idempotent).
# Generates an id from the visible text when Kramdown did not assign one.
module Jekyll
  module HeadingAnchors
    module_function

    HEADING_RE = %r{<(h[23])(\s[^>]*)?>(.*?)</\1>}mi.freeze

    def process(html)
      return html if html.nil? || html.empty?

      html.gsub(HEADING_RE) do
        tag = Regexp.last_match(1)
        attrs = Regexp.last_match(2).to_s
        inner = Regexp.last_match(3)

        # Already processed, or heading already contains a link (avoid nested <a>)
        next Regexp.last_match(0) if inner.match?(/class=["'][^"']*\bheading-anchor\b/)
        next Regexp.last_match(0) if inner.match?(/<a[\s>]/i)

        id = attrs[/\bid\s*=\s*["']([^"']+)["']/, 1]
        unless id && !id.empty?
          id = slugify(inner)
          next Regexp.last_match(0) if id.empty?

          attrs = attrs.sub(/\s*\bid\s*=\s*["'][^"']*["']/, "")
          attrs = "#{attrs} id=\"#{escape_attr(id)}\""
        end

        icon = %(<span class="heading-anchor__icon" aria-hidden="true">#</span>)
        link = %(<a class="heading-anchor" href="##{escape_attr(id)}">#{icon}#{inner}</a>)
        "<#{tag}#{attrs}>#{link}</#{tag}>"
      end
    end

    def slugify(html_fragment)
      text = html_fragment.to_s.gsub(/<[^>]+>/, " ")
      text = text.gsub("&nbsp;", " ").gsub(/&#\d+;|&\w+;/, " ")
      Jekyll::Utils.slugify(text, mode: "default")
    end

    def escape_attr(value)
      value.to_s.gsub('"', "&quot;")
    end

    def apply!(doc)
      return if doc.respond_to?(:draft?) && doc.draft?
      return if doc.output_ext && doc.output_ext != ".html"

      output = doc.output.to_s
      return if output.empty?
      return unless output.include?("<h2") || output.include?("<h3") ||
                    output.include?("<H2") || output.include?("<H3")

      doc.output = process(output)
    end
  end
end

# Mutate laid-out HTML (doc.output). Feeds use post.content, so RSS stays
# free of heading-anchor markup without a post_write disk rewrite.
Jekyll::Hooks.register :documents, :post_render do |doc|
  Jekyll::HeadingAnchors.apply!(doc)
end

Jekyll::Hooks.register :pages, :post_render do |page|
  Jekyll::HeadingAnchors.apply!(page)
end
