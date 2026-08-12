# frozen_string_literal: true

# Automatic heading permalinks for pages and posts (issue #160).
#
# After Jekyll writes the site, wrap each H2/H3 in a same-page link and
# expose a hover/focus link icon to the left. Existing heading styles are
# preserved (color/size come from the heading; the anchor is unstyled text).
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
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  # jekyll-feed can consume rendered document output. Add this presentation
  # enhancement only after every output file (including feed.xml) is written.
  # That leaves feed entries unchanged while keeping anchors on HTML pages.
  (site.pages + site.collections.values.flat_map(&:docs)).each do |doc|
    next if doc.respond_to?(:draft?) && doc.draft?
    next unless doc.output_ext == ".html"

    destination = doc.destination(site.dest)
    next unless File.file?(destination)

    File.write(destination, Jekyll::HeadingAnchors.process(File.read(destination)))
  end
end
