# frozen_string_literal: true

require "cgi"

# Publish top-level HTML drop-ins under configured roots as clean permalinks.
#
# Workflow (issue #88):
#   editorial/spacex-earnings.html  →  /editorial/spacex-earnings
#
# Critical (GH Pages + #63): the file on disk MUST keep a .html extension.
# Jekyll::StaticFile#destination is derived from #url; writing an extensionless
# path makes GitHub Pages serve application/octet-stream (browser downloads).
# Output: _site/editorial/slug.html — Pages maps /editorial/slug → that file.
#
# Sibling asset folders stay as normal static files:
#   editorial/spacex-earnings/*.png
#   editorial/media/*, editorial/assets/*
#
# Relative <img src> under the root are absolutized and, in production, passed
# through the same wsrv.nl WebP/srcset pipeline as post content.
#
# Config (_config.yml):
#   static_html:
#     roots:
#       - editorial
#       # - articles
#       # - long-form-writing
#
# HTML is never Liquid-rendered (safe to embed {{ }} in the page).
# Do not place index.html inside an asset subfolder if you want the bare
# slug URL to resolve to the sibling .html file.
module Jekyll
  class StaticHtmlFile < StaticFile
    def initialize(site, base, dir, name, content)
      super(site, base, dir, name)
      @transformed_content = content
    end

    # Force .html on disk. Parent #destination uses #url, so we must not let a
    # clean (extensionless) url become the write path.
    def destination(dest)
      @site.in_dest_dir(dest, @dir, @name)
    end

    # Public path without trailing slash (site convention #63).
    # Does not affect the write path — see #destination.
    def url
      slug = @name.sub(/\.html?\z/i, "")
      path = "/#{File.join(@dir, slug)}".gsub(%r{/+}, "/")
      if @site.baseurl && !@site.baseurl.empty?
        "#{@site.baseurl.chomp('/')}#{path}"
      else
        path
      end
    end

    def write(dest)
      dest_path = destination(dest)
      FileUtils.mkdir_p(File.dirname(dest_path))
      File.write(dest_path, @transformed_content)
      true
    end
  end

  class StaticHtmlGenerator < Generator
    safe true
    priority :low

    DEFAULT_ROOTS = %w[editorial].freeze

    def generate(site)
      roots = roots_for(site)
      return if roots.empty?

      managed = []

      roots.each do |root|
        abs_root = File.join(site.source, root)
        next unless File.directory?(abs_root)

        Dir.children(abs_root).each do |entry|
          next unless entry.match?(/\.html?\z/i)
          next if entry.start_with?(".")

          full = File.join(abs_root, entry)
          next unless File.file?(full)

          managed << File.join(root, entry).tr("\\", "/")
          content = File.read(full, encoding: "UTF-8")
          content = rewrite_images(site, content, root)

          site.static_files << StaticHtmlFile.new(
            site,
            site.source,
            root,
            entry,
            content
          )
        end
      end

      return if managed.empty?

      # Drop the default StaticFile copies so we do not write twice.
      managed_set = managed.each_with_object({}) { |p, h| h[p] = true }
      site.static_files.reject! do |sf|
        rel = sf.relative_path.to_s.sub(%r{\A/}, "").tr("\\", "/")
        managed_set[rel] && !sf.is_a?(StaticHtmlFile)
      end

      Jekyll.logger.info(
        "StaticHtml:",
        "permalink pages for #{managed.size} file(s) under #{roots.join(', ')}"
      )
    end

    def roots_for(site)
      cfg = site.config["static_html"] || {}
      list = cfg["roots"]
      list = DEFAULT_ROOTS if list.nil?
      Array(list).map(&:to_s).map(&:strip).reject(&:empty?)
    end

    def rewrite_images(site, html, root)
      return html if html.nil? || html.empty?

      out = html.gsub(/<img\b([^>]*?)>/i) do
        raw = Regexp.last_match(0)
        attrs_str = Regexp.last_match(1).sub(%r{/\s*\z}, "")
        attrs = parse_attrs(attrs_str)
        src = attrs["src"].to_s.strip
        next raw if src.empty? || src.start_with?("data:", "#")

        abs = absolutize_src(site, src, root)
        attrs["src"] = abs if abs
        next raw unless abs

        if defined?(Jekyll::OptimizeContentImages)
          enhanced = try_optimize_img(site, attrs)
          next enhanced if enhanced
        end

        "<img #{serialize_attrs(attrs)}>"
      end

      out
    end

    def absolutize_src(site, src, root)
      return src if src.match?(%r{\A(?:https?:)?//}i)
      return src if src.start_with?("/")

      cleaned = src.sub(%r{\A\./}, "")
      path = "/#{root}/#{cleaned}".gsub(%r{/+}, "/")
      baseurl = site.baseurl.to_s.chomp("/")
      "#{baseurl}#{path}"
    end

    def try_optimize_img(site, attrs)
      index = 0
      cfg = Jekyll::OptimizeContentImages.config(site)
      result = Jekyll::OptimizeContentImages.enhance_img_tag(site, cfg, attrs.dup, index)
      return nil unless result

      tag, _lcp = result
      tag
    rescue StandardError => e
      Jekyll.logger.warn("StaticHtml:", "image optimize skipped: #{e.message}")
      nil
    end

    def parse_attrs(attr_str)
      attrs = {}
      attr_str.to_s.scan(/([^\s=]+)(?:=(?:"([^"]*)"|'([^']*)'|([^\s"'>]+)))?/i) do |name, dq, sq, bare|
        attrs[name.downcase] = dq || sq || bare || ""
      end
      attrs
    end

    def serialize_attrs(attrs)
      attrs.map do |key, val|
        if val.nil? || val == ""
          key
        else
          %(#{key}="#{val.to_s.gsub('&', '&amp;').gsub('"', '&quot;')}")
        end
      end.join(" ")
    end
  end
end
