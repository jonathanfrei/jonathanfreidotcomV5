# frozen_string_literal: true

# Liquid filters for list excerpts (#186).
module Jekyll
  module ContentFilters
    # 2 paragraphs when those two are already substantial; otherwise 3.
    def extended_excerpt(input)
      html = input.to_s
      return html if html.strip.empty?

      blocks = html.split(/(?<=<\/p>)/i).map(&:strip).reject(&:empty?)
      blocks = html.split(/\n{2,}/).map(&:strip).reject(&:empty?) if blocks.size < 2
      return html if blocks.size <= 2

      first_two = blocks.first(2).join
      text_len = first_two.gsub(/<[^>]+>/, " ").gsub(/\s+/, " ").strip.length
      take = text_len >= 400 ? 2 : [3, blocks.size].min
      blocks.first(take).join
    end
  end
end

Liquid::Template.register_filter(Jekyll::ContentFilters)
