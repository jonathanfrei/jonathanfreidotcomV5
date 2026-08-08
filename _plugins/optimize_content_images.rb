# frozen_string_literal: true

require "cgi"
require "uri"

# Improve PageSpeed image audits for post/page content without visible quality loss:
#   - width/height from intrinsic file dimensions (fixes unsized-images / CLS)
#   - loading=lazy for below-fold images; first image gets fetchpriority=high
#   - decoding=async
#   - responsive srcset via wsrv.nl (resize + WebP) while data-full-src keeps full-res
#
# Runs after Markdown → HTML (post_render). Applies to:
#   - Archive media (jsDelivr CDN or local /media/)
#   - Site assets under /assets/ (served via GitHub Pages + Cloudflare)
#   - Same-origin absolute URLs for this site
#
# External third-party images (e.g. Unsplash) are left alone.
#
# Config (under archive_media.optimize in _config.yml — shared with archive CDN):
#   enabled: auto|true|false   # auto → on in production
#   proxy: "https://wsrv.nl"
#   quality: 85                # WebP quality (high; visually near-lossless for photos)
#   widths: [480, 768, 1100]   # display widths for srcset (retina covered by 1100)
#   sizes: "(max-width: 40em) 92vw, 33em"
#
# Performance: dimensions and path lookups are memoized per build so the same
# archive image referenced across many posts is only opened once.
module Jekyll
  module OptimizeContentImages
    # Own images: archive media CDN, local /media/, site /assets/, or same-origin site URL.
    OWN_MEDIA = %r{
      \A
      (?:
        https?://cdn\.jsdelivr\.net/gh/[^"'>\\s]+/_posts/v[123]-archive/media/
        |
        https?://(?:www\.)?jonathanfrei\.com/(?:assets/|media/)
        |
        /(?:[^"'>\\s]*/)?(?:assets|media)/
        |
        (?:assets|media)/
      )
    }ix.freeze

    DEFAULTS = {
      "enabled" => "auto",
      "proxy" => "https://wsrv.nl",
      "quality" => 85,
      "widths" => [480, 768, 1100],
      "sizes" => "(max-width: 40em) 92vw, 33em"
    }.freeze

    # Per-build memoization: same file is referenced across many posts.
    @dims_cache = {}
    @path_cache = {}
    @enabled_cache = {}

    module_function

    def reset_caches!
      @dims_cache = {}
      @path_cache = {}
      @enabled_cache = {}
    end

    def config(site)
      am = site.config["archive_media"] || {}
      DEFAULTS.merge(am["optimize"] || {})
    end

    def enabled?(site)
      key = site.object_id
      return @enabled_cache[key] if @enabled_cache.key?(key)

      raw = ENV["IMAGE_OPTIMIZE"].to_s.strip
      raw = config(site)["enabled"].to_s.strip if raw.empty?
      result = case raw.downcase
               when "true", "1", "yes", "on" then true
               when "false", "0", "no", "off" then false
               else
                 Jekyll.env == "production"
               end
      @enabled_cache[key] = result
      result
    end

    # --- Intrinsic dimensions (no gem dependency) ---

    def image_dimensions(path)
      return nil unless path && File.file?(path)
      return @dims_cache[path] if @dims_cache.key?(path)

      dims = File.open(path, "rb") do |f|
        head = f.read(16)
        f.rewind
        case head
        when /\A\xFF\xD8/n then jpeg_dimensions(f)
        when /\A\x89PNG\r\n\x1A\n/n then png_dimensions(f)
        when /\AGIF8[79]a/n then gif_dimensions(f)
        when /\ARIFF....WEBP/n then webp_dimensions(f)
        end
      end
      @dims_cache[path] = dims
      dims
    rescue StandardError
      @dims_cache[path] = nil
      nil
    end

    def jpeg_dimensions(f)
      return nil unless f.read(2) == "\xFF\xD8".b

      loop do
        marker = f.read(2)
        break unless marker && marker.bytesize == 2 && marker.getbyte(0) == 0xFF

        code = marker.getbyte(1)
        # Standalone markers without length
        next if (0xD0..0xD9).cover?(code) || code == 0x01

        len_bytes = f.read(2)
        break unless len_bytes && len_bytes.bytesize == 2

        length = len_bytes.unpack1("n")
        break if length < 2

        if [0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF].include?(code)
          data = f.read(length - 2)
          break unless data && data.bytesize >= 5

          _precision, height, width = data.unpack("Cnn")
          return [width, height] if width.positive? && height.positive?

          break
        end

        f.seek(length - 2, IO::SEEK_CUR)
      end
      nil
    end

    def png_dimensions(f)
      f.seek(16)
      width, height = f.read(8).unpack("NN")
      width.positive? && height.positive? ? [width, height] : nil
    end

    def gif_dimensions(f)
      f.seek(6)
      width, height = f.read(4).unpack("vv")
      width.positive? && height.positive? ? [width, height] : nil
    end

    def webp_dimensions(f)
      f.seek(12)
      fourcc = f.read(4)
      case fourcc
      when "VP8 "
        f.seek(26)
        data = f.read(4)
        return nil unless data && data.bytesize == 4

        w = data.getbyte(0) | (data.getbyte(1) << 8)
        h = data.getbyte(2) | (data.getbyte(3) << 8)
        # 14-bit widths
        [(w & 0x3FFF), (h & 0x3FFF)]
      when "VP8L"
        f.seek(21)
        b = f.read(4)
        return nil unless b && b.bytesize == 4

        bits = b.unpack1("V")
        w = (bits & 0x3FFF) + 1
        h = ((bits >> 14) & 0x3FFF) + 1
        [w, h]
      when "VP8X"
        f.seek(24)
        b = f.read(6)
        return nil unless b && b.bytesize == 6

        w = 1 + b.getbyte(0) + (b.getbyte(1) << 8) + (b.getbyte(2) << 16)
        h = 1 + b.getbyte(3) + (b.getbyte(4) << 8) + (b.getbyte(5) << 16)
        [w, h]
      end
    end

    # Map CDN, /media/, or /assets/ URL back to a local source file for dimension reads.
    def local_path_for_src(site, src)
      return nil if src.nil? || src.empty?

      path = src.to_s
      cache_key = "#{site.source}\0#{path}"
      return @path_cache[cache_key] if @path_cache.key?(cache_key)

      result = nil
      if (m = path.match(%r{/_posts/v[123]-archive/media/(.+?)(?:\?|$)}i))
        rel = CGI.unescape(m[1]).tr("\\", "/")
        %w[
          _posts/v1-archive/media
          _posts/v2-archive/media
          _posts/v3-archive/media
        ].each do |dir|
          full = File.join(site.source, dir, rel)
          if File.file?(full)
            result = full
            break
          end
        end
      elsif (m = path.match(%r{(?:\A|/)media/(.+?)(?:\?|$)}i))
        rel = CGI.unescape(m[1]).tr("\\", "/")
        %w[
          _posts/v1-archive/media
          _posts/v2-archive/media
          _posts/v3-archive/media
        ].each do |dir|
          full = File.join(site.source, dir, rel)
          if File.file?(full)
            result = full
            break
          end
        end
      elsif (m = path.match(%r{(?:\A|/)assets/(.+?)(?:\?|$)}i))
        rel = CGI.unescape(m[1]).tr("\\", "/")
        full = File.join(site.source, "assets", rel)
        result = full if File.file?(full)
      end

      @path_cache[cache_key] = result
      result
    end

    def own_media?(src)
      return false if src.nil? || src.empty?
      return false if src.start_with?("data:")

      return true if src.match?(OWN_MEDIA)

      # Same-origin absolute URL for this site (any path with an image extension)
      if (m = src.match(%r{\Ahttps?://(?:www\.)?jonathanfrei\.com(/[^"'>\s]+)}i))
        return m[1].match?(/\.(jpe?g|png|gif|webp|avif)(?:\?|$)/i)
      end

      src.include?("/_posts/v1-archive/media/") ||
        src.include?("/_posts/v2-archive/media/") ||
        src.include?("/_posts/v3-archive/media/")
    end

    def animated_or_svg?(src)
      src.to_s.match?(/\.(gif|svg)(?:\?|$)/i)
    end

    def strip_protocol(url)
      url.sub(%r{\Ahttps?://}i, "")
    end

    # Ensure origin is an absolute https URL so wsrv.nl can fetch it.
    def absolute_origin(site, src)
      s = src.to_s
      return s if s.match?(%r{\Ahttps?://}i)

      base = (site.config["url"] || "https://jonathanfrei.com").to_s.chomp("/")
      path = s.start_with?("/") ? s : "/#{s}"
      # Drop baseurl if present in path already; site.url is the public origin.
      "#{base}#{path}"
    end

    def optimized_url(cfg, origin_url, width:, format: "webp")
      proxy = cfg["proxy"].to_s.chomp("/")
      q = cfg["quality"].to_i
      q = 85 if q <= 0 || q > 100
      params = {
        "url" => strip_protocol(origin_url),
        "w" => width.to_s,
        "output" => format,
        "q" => q.to_s,
        "we" => "" # without enlargement
      }
      # we= is a flag; build query carefully
      query = "url=#{CGI.escape(params['url'])}&w=#{width}&output=#{format}&q=#{q}&we"
      "#{proxy}/?#{query}"
    end

    def parse_attrs(attr_str)
      attrs = {}
      attr_str.to_s.scan(/([^\s=]+)(?:=(?:"([^"]*)"|'([^']*)'|([^\s"'>]+)))?/i) do |name, dq, sq, bare|
        key = name.downcase
        val = dq || sq || bare || ""
        attrs[key] = val
      end
      attrs
    end

    def serialize_attrs(attrs, order)
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

    def format_attr(key, val)
      if val.nil? || val == true || val == ""
        # boolean / empty flags: only emit bare name for known empties
        return key if val == true || val == ""

        return %(#{key}="#{escape_attr(val)}")
      end
      %(#{key}="#{escape_attr(val)}")
    end

    def escape_attr(val)
      # Adjacent string literals build entities without embedding entity sequences
      # in source (those can be decoded accidentally when transferred via HTML-aware APIs).
      val.to_s.gsub("&", "&" "amp;").gsub('"', "&" "quot;")
    end

    def build_srcset(cfg, origin, widths, format: "webp")
      widths.map { |w| "#{optimized_url(cfg, origin, width: w, format: format)} #{w}w" }.join(", ")
    end

    def enhance_img_tag(site, cfg, tag_attrs, index)
      src = tag_attrs["src"]
      return nil unless own_media?(src)
      return nil if tag_attrs["data-img-opt"] == "1"

      # Origin URL for full-quality link / optimizer source (must be absolute for wsrv)
      origin = absolute_origin(site, src)

      # Skip transform for GIF/SVG (animation / vectors)
      transform = enabled?(site) && !animated_or_svg?(src)

      local = local_path_for_src(site, src)
      dims = local ? image_dimensions(local) : nil
      natural_w = dims && dims[0]
      natural_h = dims && dims[1]

      # Prefer intrinsic dimensions; keep existing only if intrinsic unknown
      if natural_w && natural_h
        tag_attrs["width"] = natural_w.to_s
        tag_attrs["height"] = natural_h.to_s
      end

      tag_attrs["decoding"] = "async" unless tag_attrs.key?("decoding")

      if index.zero?
        tag_attrs["loading"] = "eager"
        tag_attrs["fetchpriority"] = "high"
      else
        tag_attrs["loading"] = "lazy" unless tag_attrs.key?("loading")
        tag_attrs.delete("fetchpriority")
      end

      lcp_candidate = nil

      if transform
        widths = Array(cfg["widths"]).map(&:to_i).select(&:positive?).uniq.sort
        # Do not upscale past natural width
        widths = widths.select { |w| natural_w.nil? || w <= natural_w }
        widths = [natural_w].compact if widths.empty? && natural_w
        widths = [1100] if widths.empty?

        default_w = widths.max
        sizes = cfg["sizes"].to_s
        sizes = DEFAULTS["sizes"] if sizes.empty?

        tag_attrs["src"] = optimized_url(cfg, origin, width: default_w, format: "webp")
        tag_attrs["srcset"] = build_srcset(cfg, origin, widths, format: "webp")
        tag_attrs["sizes"] = sizes unless tag_attrs.key?("sizes")
        tag_attrs["data-img-opt"] = "1"
        # Preserve original for debugging / optional full-res openers
        tag_attrs["data-full-src"] = origin

        lcp_candidate = tag_attrs["src"] if index.zero?
      else
        tag_attrs["data-img-opt"] = "1"
        lcp_candidate = origin if index.zero?
      end

      order = %w[
        src srcset sizes width height alt title class loading decoding
        fetchpriority data-full-src data-img-opt
      ]
      ["<img #{serialize_attrs(tag_attrs, order)}>", lcp_candidate]
    end

    def process_html(site, html)
      return [html, nil] if html.nil? || html.empty?
      # Fast path: skip documents with no images
      return [html, nil] unless html.include?("<img") || html.include?("<IMG")

      cfg = config(site)
      index = 0
      lcp = nil

      out = html.gsub(/<img\b([^>]*?)>/i) do
        raw_attrs = Regexp.last_match(1)
        original = Regexp.last_match(0)
        # Skip self-closing slash noise
        attrs = parse_attrs(raw_attrs.sub(%r{/\s*\z}, ""))
        enhanced = enhance_img_tag(site, cfg, attrs, index)
        if enhanced
          tag, candidate = enhanced
          lcp ||= candidate
          index += 1
          tag
        else
          original
        end
      end

      [out, lcp]
    end

    # Inject preload even when post_render runs after the layout (so Liquid
    # {{ page.lcp_image }} may have already been evaluated empty).
    def inject_lcp_preload(html, lcp_url)
      return html if lcp_url.nil? || lcp_url.empty?
      return html if html.include?('rel="preload"') && html.include?(lcp_url)

      tag = %(<link rel="preload" as="image" href="#{escape_attr(lcp_url)}" fetchpriority="high">\n)
      if html.sub!(%r{</head>}i, "#{tag}</head>")
        html
      else
        html
      end
    end

    def process_document(doc)
      site = doc.site
      return unless doc.respond_to?(:output) && doc.output

      new_html, lcp = process_html(site, doc.output)
      doc.data["lcp_image"] = lcp if lcp
      new_html = inject_lcp_preload(new_html, lcp) if lcp && new_html.include?("</head>")
      doc.output = new_html
    end
  end
end

Jekyll::Hooks.register :site, :after_init do |_site|
  Jekyll::OptimizeContentImages.reset_caches!
end

Jekyll::Hooks.register :posts, :post_render do |post|
  Jekyll::OptimizeContentImages.process_document(post)
end

Jekyll::Hooks.register :pages, :post_render do |page|
  # Only HTML-ish pages; skip feeds/assets
  next if page.output_ext && page.output_ext != ".html"

  Jekyll::OptimizeContentImages.process_document(page)
end
