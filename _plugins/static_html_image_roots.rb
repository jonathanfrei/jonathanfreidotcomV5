# frozen_string_literal: true

require "cgi"

# Extend OptimizeContentImages so static_html roots (editorial, etc.) count as
# own media for wsrv.nl WebP/srcset (issue #88 + #90).
#
# Loaded after optimize_content_images.rb (alphabetical order under _plugins/).
module Jekyll
  module OptimizeContentImages
    class << self
      alias_method :own_media_without_static_html?, :own_media? if method_defined?(:own_media?)

      def own_media?(src, site = nil)
        return false if src.nil? || src.empty?
        return false if src.start_with?("data:")

        # Prefer original implementation when present
        if respond_to?(:own_media_without_static_html?)
          begin
            return true if own_media_without_static_html?(src)
          rescue ArgumentError
            return true if own_media_without_static_html?(src, site)
          end
        end

        roots = Array(((site && site.config["static_html"]) || {})["roots"] || %w[editorial])
        roots.each do |root|
          root = root.to_s.strip.sub(%r{\A/+}, "").sub(%r{/+\z}, "")
          next if root.empty?
          return true if src.include?("/#{root}/") || src.match?(%r{\A/?#{Regexp.escape(root)}/}i)
        end

        if (m = src.match(%r{\Ahttps?://(?:www\.)?jonathanfrei\.com(/[^"'\s>]+)}i))
          return m[1].match?(/\.(jpe?g|png|gif|webp|avif)(?:\?|$)/i)
        end

        false
      end
    end

    # Also resolve local files under static_html roots for dimension reads.
    class << self
      alias_method :local_path_for_src_without_static_html, :local_path_for_src if method_defined?(:local_path_for_src)

      def local_path_for_src(site, src)
        if respond_to?(:local_path_for_src_without_static_html)
          found = local_path_for_src_without_static_html(site, src)
          return found if found
        end

        return nil if src.nil? || src.empty?

        roots = Array((site.config["static_html"] || {})["roots"] || %w[editorial])
        roots.each do |root|
          root = root.to_s.strip.sub(%r{\A/+}, "").sub(%r{/+\z}, "")
          next if root.empty?
          if (m = src.match(%r{(?:\A|/)#{Regexp.escape(root)}/(.+?)(?:\?|$)}i))
            rel = CGI.unescape(m[1]).tr("\\", "/")
            full = File.join(site.source, root, rel)
            return full if File.file?(full)
          end
        end
        nil
      end
    end
  end
end
