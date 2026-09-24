# frozen_string_literal: true

# Shared HTML attribute + Markdown plain-text helpers (dedup).
#
# Single source of truth for logic previously duplicated across
# optimize_content_images.rb, static_html_pages.rb, site_index.rb,
# post_metadata.rb, and link_posts.rb. All rewired call sites delegate
# here; observable output at each site is unchanged.
module Jekyll
  module HtmlUtil
    module_function

    # Parse HTML attributes (double/single/bare/boolean), keys downcased.
    # Semantics match OptimizeContentImages.parse_attrs.
    def parse_attrs(attr_str)
      attrs = {}
      attr_str.to_s.scan(/([^\s=]+)(?:=(?:"([^"]*)"|'([^']*)'|([^\s"'>]+)))?/i) do |name, dq, sq, bare|
        key = name.downcase
        val = dq || sq || bare || ""
        attrs[key] = val
      end
      attrs
    end

    # Ordered-first then remainder, key="escaped".
    # Matches OptimizeContentImages.serialize_attrs.
    def serialize_attrs(attrs, order = [])
      parts = []
      seen = {}
      order.each do |key|
        next unless attrs.key?(key)

        parts << format_attr(key, attrs[key])
        seen[key] = true
      end
      attrs.each do |key, val|
        next if seen[key]

        parts << format_attr(key, val)
      end
      parts.join(" ")
    end

    # Matches OptimizeContentImages.format_attr.
    def format_attr(key, val)
      if val.nil? || val == true || val == ""
        # boolean / empty flags: only emit bare name for known empties
        return key if val == true || val == ""

        return %(#{key}="#{escape_attr(val)}")
      end
      %(#{key}="#{escape_attr(val)}")
    end

    # Matches OptimizeContentImages.escape_attr.
    def escape_attr(val)
      # Adjacent string literals build entities without embedding entity sequences
      # in source (those can be decoded accidentally when transferred via HTML-aware APIs).
      val.to_s.gsub("&", "&" "amp;").gsub('"', "&" "quot;")
    end

    # Shared Markdown→plain-text stripping core for PostMetadata.word_count
    # and SiteIndex.plain_text.
    #
    # The two call sites have observable differences, preserved via flags:
    # - word_count does NOT collapse whitespace or strip IALs (it splits on \s+).
    # - plain_text DOES collapse whitespace and strip {::...} IALs.
    #
    # IAL stripping runs before the [#>*_\-|] collapse so `{:.figure-wide}`
    # never becomes `{: .figure wide}`.
    def strip_markdown_text(input, collapse_whitespace: false, strip_ials: false)
      text = input.to_s.dup
      # Fenced code, inline code, images, HTML tags — keep link labels
      text.gsub!(/```.*?```/m, " ")
      text.gsub!(/`[^`]*`/, " ")
      text.gsub!(/!\[[^\]]*\]\([^)]*\)/, " ")
      text.gsub!(/\[([^\]]*)\]\([^)]*\)/, '\1')
      text.gsub!(/<[^>]+>/, " ")
      # Kramdown IALs / ALDs ({: .figure-wide}, {: .caption}, {::comment}).
      # Strip before hyphen collapsing (see SiteIndex.plain_text).
      text.gsub!(/\{::?[^}]*\}/, " ") if strip_ials
      text.gsub!(/[#>*_\-|]+/, " ")
      if collapse_whitespace
        text.gsub!(/\s+/, " ")
        text.strip
      else
        text
      end
    end

    # Kramdown keeps CommonMark \( \) escapes in the destination; cmark/GitHub
    # unescapes them. Those leftover backslashes 404 on origin and wsrv.nl
    # (e.g. file_\(1957\).jpg vs file_(1957).jpg).
    def unescape_markdown_dest(src)
      src.to_s.gsub(/\\([()\\])/, '\1')
    end
  end
end
