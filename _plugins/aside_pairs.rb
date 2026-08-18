# frozen_string_literal: true

# Pair `{: .aside}` with a neighboring paragraph so CSS can put the aside
# beside that paragraph on wide screens and under it on small ones (#223, #232).
# Prefer the following paragraph (typography.md). If the next sibling is not a
# host paragraph — often a heading — pair with the preceding paragraph instead.
# A code sample between the host and the aside is left in place; the aside is
# lifted next to the host so the margin column still hugs the paragraph.
# The wrapper always lists the host first so screen readers hear the paragraph
# before the sidenote (#232).
# Editorial grid asides (`<div class="aside">` on layout: editorial) are left
# alone.
module Jekyll
  module AsidePairs
    P_TAG = %r{<p\b[^>]*>(?:(?!</p>).)*</p>}im
    ASIDE_CLASS = /\A<p\b[^>]*\bclass\s*=\s*["'][^"']*\baside\b/i
    ONLY_GAP = /\A(?:\s+|<!--.*?-->)*\z/m
    HIGHLIGHT_DIV = /\A<div\b[^>]*\bclass\s*=\s*["'][^"']*\b(?:highlighter-rouge|highlight|language-)/i

    module_function

    def wrap(html)
      return html if html.nil? || html.empty?
      return html unless html.match?(/class\s*=\s*["'][^"']*\baside\b/)

      paragraphs = []
      pos = 0
      while (match = html.match(P_TAG, pos))
        paragraphs << { start: match.begin(0), finish: match.end(0), text: match[0] }
        pos = match.end(0)
      end

      used = {}
      replacements = []

      paragraphs.each_with_index do |para, index|
        next unless aside_paragraph?(para[:text])
        next if used[index]
        next if already_paired?(html, para[:start])

        host_index = neighbor_host(html, paragraphs, index, used)
        next if host_index.nil?

        host = paragraphs[host_index]
        used[index] = true
        used[host_index] = true
        replacements.concat(pair_replacements(html, para, host))
      end

      replacements.sort_by! { |start, _, _| -start }
      replacements.each do |start, finish, wrapped|
        html = "#{html[0...start]}#{wrapped}#{html[finish..]}"
      end
      html
    end

    def apply!(doc)
      return if doc.data["layout"].to_s == "editorial"
      return unless doc.respond_to?(:content)

      html = doc.content.to_s
      wrapped = wrap(html)
      doc.content = wrapped unless wrapped.equal?(html) || wrapped == html
    end

    def aside_paragraph?(html)
      html.match?(ASIDE_CLASS)
    end

    def already_paired?(html, start)
      before = html[0...start]
      last_open = before.rindex(/<div\b[^>]*\bclass\s*=\s*["'][^"']*\baside-pair\b/i)
      return false unless last_open

      last_close = before.rindex("</div>")
      last_close.nil? || last_close < last_open
    end

    def only_gap?(html, from, to)
      return false if to < from

      html[from...to].match?(ONLY_GAP)
    end

    def neighbor_host(html, paragraphs, index, used)
      following = paragraphs[index + 1]
      if following && !used[index + 1] && !aside_paragraph?(following[:text]) &&
         only_gap?(html, paragraphs[index][:finish], following[:start])
        return index + 1
      end

      return if index.zero?

      previous = paragraphs[index - 1]
      return unless previous && !used[index - 1] && !aside_paragraph?(previous[:text])
      gap_ok = only_gap?(html, previous[:finish], paragraphs[index][:start]) ||
               skippable_between?(html, previous[:finish], paragraphs[index][:start])
      return unless gap_ok

      index - 1
    end

    # Adjacent siblings can be wrapped in place. If a code sample sits
    # between the host and the aside, lift the aside next to the host and
    # leave the sample where it is. Host is always first for reading order.
    def pair_replacements(html, aside, host)
      first, last = aside[:start] < host[:start] ? [aside, host] : [host, aside]
      wrapped = %(<div class="aside-pair">#{host[:text]}\n#{aside[:text]}</div>)
      if only_gap?(html, first[:finish], last[:start])
        return [[first[:start], last[:finish], wrapped]]
      end

      [
        [last[:start], last[:finish], ""],
        [first[:start], first[:finish], wrapped]
      ]
    end

    def skippable_between?(html, from, to)
      return false if to < from

      pos = from
      while pos < to
        rest = html[pos...to]
        if (space = rest[/\A\s+/])
          pos += space.length
          next
        end
        if rest.start_with?("<!--")
          close = html.index("-->", pos)
          return false unless close && close + 3 <= to

          pos = close + 3
          next
        end
        if rest.match?(/\A<pre\b/i)
          close = end_of_element(html, pos, "pre")
          return false unless close && close <= to

          pos = close
          next
        end
        if rest.match?(HIGHLIGHT_DIV)
          close = end_of_element(html, pos, "div")
          return false unless close && close <= to

          pos = close
          next
        end
        return false
      end
      true
    end

    def end_of_element(html, start, tag)
      scanner = /<(\/?)#{Regexp.escape(tag)}\b[^>]*>/i
      depth = 0
      pos = start
      while (match = html.match(scanner, pos))
        depth += match[1] == "/" ? -1 : 1
        pos = match.end(0)
        return pos if depth.zero?
      end
      nil
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
