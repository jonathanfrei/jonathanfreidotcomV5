# frozen_string_literal: true

# Liquid filters for list excerpts (#186).
module Jekyll
  module ContentFilters
    # 2 paragraphs when those two are already substantial; otherwise 3.
    # Only <p> blocks so heading/embed markup after a paragraph is not pulled in.
    def self.excerpt_html(input)
      html = input.to_s
      return html if html.strip.empty?

      paragraphs = html.scan(/<p(?:\s[^>]*)?>.*?<\/p>/im)
      return html if paragraphs.empty?

      # GIF-only paragraphs stay on the permalink; they are too heavy for
      # /blog and other list excerpts (e.g. an 11MB Giphy on a short post).
      paragraphs = paragraphs.reject { |p| gif_only_paragraph?(p) }
      return "" if paragraphs.empty?
      return paragraphs.join if paragraphs.size <= 2

      first_two = paragraphs.first(2).join
      text_len = first_two.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip.length
      take = text_len >= 400 ? 2 : 3
      paragraphs.first(take).join
    end

    def extended_excerpt(input)
      Jekyll::ContentFilters.excerpt_html(input)
    end

    def self.gif_only_paragraph?(html)
      has_gif = html.match?(/<img\b[^>]*\bsrc\s*=\s*["']?[^"'\s>]+\.gif(?:\?[^"'\s>]*)?/i)
      return false unless has_gif

      text = html.gsub(/<img\b[^>]*>/i, "")
                 .gsub(%r{</?a\b[^>]*>}i, "")
                 .gsub(/<[^>]+>/, " ")
                 .gsub("&nbsp;", " ")
                 .gsub(/\s+/, " ")
                 .strip
      text.empty?
    end
  end
end

Liquid::Template.register_filter(Jekyll::ContentFilters)

# Posts render before pages. Stash a list blurb so /blog does not walk
# full converted HTML through extended_excerpt on every list item.
Jekyll::Hooks.register :documents, :post_render do |doc|
  next unless doc.respond_to?(:collection) && doc.collection&.label == "posts"
  next if doc.data["layout"].to_s == "link"

  html = doc.content.to_s
  next if html.strip.empty?

  doc.data["list_excerpt"] = Jekyll::ContentFilters.excerpt_html(html)
end
