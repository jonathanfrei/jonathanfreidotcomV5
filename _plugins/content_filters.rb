# frozen_string_literal: true

# Liquid filters for list excerpts (#186).
module Jekyll
  module ContentFilters
    # 2 paragraphs when those two are already substantial; otherwise 3.
    # Only <p> blocks so heading/embed markup after a paragraph is not pulled in.
    def extended_excerpt(input)
      html = input.to_s
      return html if html.strip.empty?

      paragraphs = html.scan(/<p(?:\s[^>]*)?>.*?<\/p>/im)
      return html if paragraphs.empty?
      return paragraphs.join if paragraphs.size <= 2

      first_two = paragraphs.first(2).join
      text_len = first_two.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip.length
      take = text_len >= 400 ? 2 : 3
      paragraphs.first(take).join
    end
  end
end

Liquid::Template.register_filter(Jekyll::ContentFilters)
