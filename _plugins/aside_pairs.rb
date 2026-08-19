# frozen_string_literal: true

# Pair a top-level `.aside` block with the block immediately before it so CSS
# can put the aside beside that host on wide screens and under it on small
# ones (#223, #232). The aside may be a paragraph or a multi-block container
# such as an image and caption wrapped in `<div class="aside">`.
#
# The wrapper always lists the host first so reading and focus order match the
# article. Editorial grid asides (layout: editorial) are left alone.
module Jekyll
  module AsidePairs
    TAG = /<!--.*?-->|<![^>]*>|<\?[^>]*>|<\/?([a-z][\w:-]*)\b[^>]*>/im
    CLASS_ATTRIBUTE = /\A<[a-z][\w:-]*\b[^>]*\bclass\s*=\s*(["'])(.*?)\1/im
    VOID_TAGS = %w[area base br col embed hr img input link meta param source track wbr].freeze

    module_function

    def wrap(html)
      return html if html.nil? || html.empty?
      return html unless html.match?(/class\s*=\s*["'][^"']*\baside\b/)

      blocks = top_level_elements(html)
      used = {}
      replacements = []

      blocks.each_with_index do |aside, index|
        next unless aside_block?(aside[:text])
        next if index.zero? || used[index]

        host_index = index - 1
        host = blocks[host_index]
        next if used[host_index] || aside_block?(host[:text])

        used[index] = true
        used[host_index] = true
        gap = html[host[:finish]...aside[:start]]
        wrapped = %(<div class="aside-pair">#{host[:text]}#{gap}#{aside[:text]}</div>)
        replacements << [host[:start], aside[:finish], wrapped]
      end

      replacements.reverse_each do |start, finish, wrapped|
        html = "#{html[0...start]}#{wrapped}#{html[finish..]}"
      end
      html
    end

    def apply!(doc)
      return if doc.data["layout"].to_s == "editorial"
      return unless doc.respond_to?(:content)

      html = doc.content.to_s
      wrapped = wrap(html)
      doc.content = wrapped unless wrapped == html
    end

    def aside_block?(html)
      classes = html.match(CLASS_ATTRIBUTE)&.[](2)
      classes&.split&.include?("aside")
    end

    # Kramdown emits a fragment whose article blocks are top-level siblings.
    # Track tag depth so a container aside and all of its children stay one
    # movable element without requiring an HTML parser dependency.
    def top_level_elements(html)
      blocks = []
      stack = []
      element_start = nil

      html.to_enum(:scan, TAG).each do
        match = Regexp.last_match
        token = match[0]
        tag = match[1]&.downcase
        next unless tag

        if token.match?(/\A<\//)
          close_index = stack.rindex(tag)
          next unless close_index

          stack.slice!(close_index..)
          if stack.empty? && element_start
            blocks << element(html, element_start, match.end(0))
            element_start = nil
          end
          next
        end

        element_start = match.begin(0) if stack.empty?
        self_closing = token.match?(/\/\s*>\z/) || VOID_TAGS.include?(tag)
        if self_closing
          if stack.empty?
            blocks << element(html, element_start, match.end(0))
            element_start = nil
          end
        else
          stack << tag
        end
      end

      blocks
    end

    def element(html, start, finish)
      { start: start, finish: finish, text: html[start...finish] }
    end
  end
end

if defined?(Jekyll::Hooks)
  [:documents, :pages].each do |owner|
    Jekyll::Hooks.register owner, :post_convert do |doc|
      Jekyll::AsidePairs.apply!(doc)
    end
  end
end
