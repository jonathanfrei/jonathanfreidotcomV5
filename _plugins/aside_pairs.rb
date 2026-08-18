# frozen_string_literal: true

# Pair `{: .aside}` with the following paragraph so CSS can put the aside
# beside that paragraph on wide screens and under it on small ones (#223).
# Editorial grid asides (`<div class="aside">` on layout: editorial) are left
# alone.
module Jekyll
  module AsidePairs
    PAIR = %r{
      (?<aside>
        <p\b[^>]*\bclass\s*=\s*["'][^"']*\baside\b[^"']*["'][^>]*>
        (?:(?!</p>).)*
        </p>
      )
      (?<ws>\s*)
      (?<host>
        <p\b(?![^>]*\baside\b)[^>]*>
        (?:(?!</p>).)*
        </p>
      )
    }imx

    module_function

    def wrap(html)
      return html if html.nil? || html.empty?
      return html unless html.match?(/class\s*=\s*["'][^"']*\baside\b/)

      html.gsub(PAIR) do
        aside = Regexp.last_match(:aside)
        ws = Regexp.last_match(:ws)
        host = Regexp.last_match(:host)
        next Regexp.last_match(0) if aside.include?("aside-pair")

        %(<div class="aside-pair">#{aside}#{ws}#{host}</div>)
      end
    end

    def apply!(doc)
      return if doc.data["layout"].to_s == "editorial"
      return unless doc.respond_to?(:content)

      html = doc.content.to_s
      wrapped = wrap(html)
      doc.content = wrapped unless wrapped.equal?(html) || wrapped == html
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
