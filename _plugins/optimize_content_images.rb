# frozen_string_literal: true

require "cgi"
require "openssl"
require "uri"

# Improve PageSpeed image audits for post/page content without visible quality loss:
#   - width/height from intrinsic file dimensions (fixes unsized-images / CLS)
#   - loading=lazy for below-fold images; first image gets fetchpriority=high
#   - decoding=async
#   - responsive srcset via same-origin /img (Worker → wsrv.nl) while data-full-src keeps full-res
#   - LCP preload uses imagesrcset/imagesizes so the browser fetches one candidate (#173)
#   - preconnect media.jonathanfrei.com only when the page will fetch originals
#
# Runs after Markdown → HTML (post_render). Applies to:
#   - Archive media (S3 via media.jonathanfrei.com, or local /media/)
#   - New post photos on S3 (https://media.jonathanfrei.com/assets/img/…)
#   - Site chrome under /assets/ (served via GitHub Pages + Cloudflare)
#   - Same-origin absolute URLs for this site
#   - Hotlinked third-party images (http/https) when optimize.hotlink is on (#116)
#
# Skips transform for: data: URLs, SVG/GIF, already-proxied /img or wsrv.nl
# URLs, non-image schemes. GIFs still get loading=lazy (never LCP/eager).
# Production proxy URLs are HMAC-signed (IMG_HMAC); the Worker rejects unsigned
# requests so /img is not an open image CDN.
#
# Config (under archive_media.optimize in _config.yml — shared with archive CDN):
#   enabled: auto|true|false   # auto → on in production
#   proxy: "https://jonathanfrei.com/img"
#   quality: 85                # WebP quality (high; visually near-lossless for photos)
#   widths: [480, 768, 1100]   # display widths for srcset (retina covered by 1100)
#   sizes: "(max-width: 40em) 100vw, 36em"  # full-bleed mobile (#202); 36em = --measure
#   hotlink: true              # proxy third-party hotlinked images via wsrv (#116)
#
# Performance: dimensions and path lookups are memoized per build so the same
# archive image referenced across many posts is only opened once.
module Jekyll
  module OptimizeContentImages
    # Own images: S3 archive media, new post photos on S3 /assets/img/,
    # local /media/, in-repo /assets/ chrome, or same-origin site URL.
    # S3: media.jonathanfrei.com/v{2,3}-archive/media/… (#170)
    #      media.jonathanfrei.com/assets/img/… (upload-worker)
    OWN_MEDIA = %r{
      \A
      (?:
        https?://media\.jonathanfrei\.com/v[123]-archive/media/
        |
        https?://media\.jonathanfrei\.com/assets/img/
        |
        https?://s3\.us-east-1\.amazonaws\.com/media\.jonathanfrei\.com/v[123]-archive/media/
        |
        https?://s3\.us-east-1\.amazonaws\.com/media\.jonathanfrei\.com/assets/img/
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
      "proxy" => "https://jonathanfrei.com/img",
      "quality" => 85,
      "widths" => [480, 768, 1100],
      # Match .prose / --measure (36em). Mobile: full-bleed (#202).
      "sizes" => "(max-width: 40em) 100vw, 36em",
      "hotlink" => true
    }.freeze

    # Already going through our image CDN/proxy — do not re-proxy.
    PROXY_HOST = %r{\Ahttps?://(?:wsrv\.nl|images\.weserv\.nl|cdn\.jsdelivr\.net|(?:www\.)?jonathanfrei\.com/img)/}i.freeze

    # wsrv defaults to http when the scheme is omitted. Some origins
    # (Springer) 404 on that http fetch; force ssl: for those (#203).
    # Do not apply globally — Wikimedia 404s when ssl: is forced.
    PROXY_SSL_HOSTS = %r{\Ahttps://(?:[^/]+\.)?(?:springernature\.com|springer\.com)/}i.freeze

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
    # Works while archive media still exists under _posts/v*-archive/media/; returns
    # nil after those trees are removed from the repo (wsrv still optimizes via S3).
    def local_path_for_src(site, src)
      return nil if src.nil? || src.empty?

      path = src.to_s
      cache_key = "#{site.source}\0#{path}"
      return @path_cache[cache_key] if @path_cache.key?(cache_key)

      result = nil
      # S3 / custom domain: …/v2-archive/media/rel or s3…/media.jonathanfrei.com/v2-archive/media/rel
      if (m = path.match(%r{(?:media\.jonathanfrei\.com|/_posts)/(v[123]-archive)/media/(.+?)(?:\?|$)}i))
        slug = m[1]
        rel = CGI.unescape(m[2]).tr("\\", "/")
        full = File.join(site.source, "_posts", slug, "media", rel)
        result = full if File.file?(full)
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

      # Explicit S3 host forms already covered by OWN_MEDIA; keep path fallbacks
      src.match?(%r{/v[123]-archive/media/}i)
    end

    # Third-party hotlinked image eligible for CDN proxy (#116)
    def hotlink_media?(src)
      return false if src.nil? || src.empty?
      return false if src.start_with?("data:", "blob:", "//")
      return false unless src.match?(%r{\Ahttps?://}i)
      return false if src.match?(PROXY_HOST)
      return false if own_media?(src)
      return false if animated_or_svg?(src)

      # Prefer clear image URLs; also allow common host CDNs without extension
      return true if src.match?(/\.(jpe?g|png|webp|avif|bmp)(?:\?|#|$)/i)
      return true if src.match?(%r{https?://(?:i\.)?imgur\.com/}i)
      return true if src.match?(%r{https?://(?:live|farm\d+)\.static\.?flickr\.com/}i)
      return true if src.match?(%r{https?://(?:images?|cdn|media|static)\.}i)

      false
    end

    def card_image?(tag_attrs)
      tag_attrs.to_h["class"].to_s.split(/\s+/).include?("link-card__image")
    end

    def optimizable?(site, src, tag_attrs = {})
      # GIFs are never proxied, but they still need loading=lazy so an
      # 11MB animation is not the LCP candidate or an eager feed asset.
      return true if gif?(src)

      return true if own_media?(src)

      cfg = config(site)
      hotlink_on = cfg["hotlink"]
      hotlink_on = true if hotlink_on.nil?
      return false unless hotlink_on == true || hotlink_on.to_s.downcase == "true"

      if card_image?(tag_attrs) && src.to_s.match?(%r{\Ahttps?://}i) && !src.to_s.match?(PROXY_HOST)
        return !animated_or_svg?(src)
      end

      hotlink_media?(src)
    end

    def animated_or_svg?(src)
      src.to_s.match?(/\.(gif|svg)(?:\?|#|$)/i)
    end

    def gif?(src)
      src.to_s.match?(/\.gif(?:\?|#|$)/i)
    end

    def strip_protocol(url)
      s = url.to_s
      return s.sub(%r{\Ahttps://}i, "ssl:") if s.match?(PROXY_SSL_HOSTS)

      s.sub(%r{\Ahttps?://}i, "")
    end

    # Kramdown keeps CommonMark \( \) escapes in the destination; cmark/GitHub
    # unescapes them. Those leftover backslashes 404 on origin and wsrv.nl
    # (e.g. file_\(1957\).jpg vs file_(1957).jpg).
    def unescape_markdown_dest(src)
      src.to_s.gsub(/\\([()\\])/, '\1')
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

    def hmac_secret
      ENV["IMG_HMAC"].to_s
    end

    # Must match workers/img-proxy canonicalMessage().
    def canonical_message(inner_url, width, format, quality)
      "output=#{format}&q=#{quality}&url=#{inner_url}&w=#{width}&we"
    end

    def sign_query(inner_url, width, format, quality)
      secret = hmac_secret
      if secret.empty?
        raise "IMG_HMAC is required when image optimize is on (Worker /img HMAC)"
      end

      OpenSSL::HMAC.hexdigest("SHA256", secret, canonical_message(inner_url, width, format, quality))
    end

    def optimized_url(cfg, origin_url, width:, format: "webp")
      proxy = cfg["proxy"].to_s.chomp("/")
      q = cfg["quality"].to_i
      q = 85 if q <= 0 || q > 100
      inner = strip_protocol(origin_url)
      sig = sign_query(inner, width, format, q)
      query = "url=#{CGI.escape(inner)}&w=#{width}&output=#{format}&q=#{q}&we&s=#{sig}"
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

    def figure_wide?(html, pos, tag_attrs)
      return true if tag_attrs["class"].to_s.match?(/\bfigure-wide\b/)

      window_start = [pos - 280, 0].max
      prefix = html[window_start...pos].to_s
      prefix.match?(/<(?:p|figure|div|a)\b[^>]*\bclass\s*=\s*["'][^"']*\bfigure-wide\b[^"']*["'][^>]*>\s*(?:<a\b[^>]*>\s*)?\z/i)
    end

    def enhance_img_tag(site, cfg, tag_attrs, index, wide: false)
      src = unescape_markdown_dest(tag_attrs["src"])
      tag_attrs["src"] = src
      return nil unless optimizable?(site, src, tag_attrs)
      return nil if tag_attrs["data-img-opt"] == "1"
      return nil if src.to_s.match?(PROXY_HOST)

      is_own = own_media?(src)

      # Origin URL for full-quality link / optimizer source (must be absolute for wsrv)
      origin = absolute_origin(site, src)

      # Skip transform for GIF/SVG (animation / vectors)
      transform = enabled?(site) && !animated_or_svg?(src)

      local = is_own ? local_path_for_src(site, src) : nil
      dims = local ? image_dimensions(local) : nil
      natural_w = dims && dims[0]
      natural_h = dims && dims[1]

      # Prefer intrinsic dimensions; keep existing only if intrinsic unknown
      if natural_w && natural_h
        tag_attrs["width"] = natural_w.to_s
        tag_attrs["height"] = natural_h.to_s
      end

      # Empty alt is valid for decorative images; ensure attribute exists for a11y audits
      tag_attrs["alt"] = "" unless tag_attrs.key?("alt")

      tag_attrs["decoding"] = "async" unless tag_attrs.key?("decoding")

      # Hotlinked originals: send Referer only to same-origin /img (Worker
      # optional extra check). data-full-src fallback to Springer-class
      # hosts stays without a referrer (#203).
      unless is_own
        tag_attrs["referrerpolicy"] = "same-origin" unless tag_attrs.key?("referrerpolicy")
      end

      # Animated GIFs are often multi-megabyte. Never mark them eager/LCP,
      # including when they are the first image on the post or a list page.
      is_gif = gif?(src)
      if is_gif
        tag_attrs["loading"] = "lazy"
        tag_attrs.delete("fetchpriority")
      elsif index.zero?
        tag_attrs["loading"] = "eager"
        tag_attrs["fetchpriority"] = "high"
      else
        tag_attrs["loading"] = "lazy" unless tag_attrs.key?("loading")
        tag_attrs.delete("fetchpriority")
      end

      lcp_candidate = nil

      if transform
        widths = Array(cfg["widths"]).map(&:to_i).select(&:positive?).uniq.sort
        # Wide figures can fill the viewport; don't invent pixels past intrinsic size.
        widths = (widths + [1600, 2200]).uniq.sort if wide
        # Do not upscale past natural width when known
        widths = widths.select { |w| natural_w.nil? || w <= natural_w }
        widths = [natural_w].compact if widths.empty? && natural_w
        widths = [1100] if widths.empty?

        default_w = widths.max
        sizes = wide ? "100vw" : cfg["sizes"].to_s
        sizes = DEFAULTS["sizes"] if sizes.empty?

        tag_attrs["src"] = optimized_url(cfg, origin, width: default_w, format: "webp")
        tag_attrs["srcset"] = build_srcset(cfg, origin, widths, format: "webp")
        tag_attrs["sizes"] = sizes unless tag_attrs.key?("sizes")
        tag_attrs["data-img-opt"] = "1"
        # Preserve original for debugging / optional full-res openers
        tag_attrs["data-full-src"] = origin

        # Responsive LCP preload must share srcset/sizes with <img> or the
        # browser may preload 1100w and still fetch 768w for display (#173).
        lcp_candidate = lcp_descriptor(tag_attrs) if index.zero? && !is_gif
      else
        tag_attrs["data-img-opt"] = "1"
        lcp_candidate = { "href" => origin } if index.zero? && !is_gif
      end

      order = %w[
        src srcset sizes width height alt title class loading decoding
        fetchpriority referrerpolicy data-full-src data-img-opt
      ]
      ["<img #{serialize_attrs(tag_attrs, order)}>", lcp_candidate]
    end

    # LCP preload payload: href plus optional imagesrcset/imagesizes.
    def lcp_descriptor(tag_attrs)
      desc = { "href" => tag_attrs["src"].to_s }
      srcset = tag_attrs["srcset"].to_s
      sizes = tag_attrs["sizes"].to_s
      if !srcset.empty?
        desc["imagesrcset"] = srcset
        desc["imagesizes"] = sizes unless sizes.empty?
      end
      desc
    end

    def normalize_lcp(lcp)
      case lcp
      when Hash
        href = (lcp["href"] || lcp[:href]).to_s
        srcset = (lcp["imagesrcset"] || lcp[:imagesrcset] || lcp["srcset"] || lcp[:srcset]).to_s
        sizes = (lcp["imagesizes"] || lcp[:imagesizes] || lcp["sizes"] || lcp[:sizes]).to_s
        [href, srcset, sizes]
      when String
        [lcp, "", ""]
      else
        ["", "", ""]
      end
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
        pos = Regexp.last_match.begin(0)
        # Skip self-closing slash noise
        attrs = parse_attrs(raw_attrs.sub(%r{/\s*\z}, ""))
        wide = figure_wide?(html, pos, attrs)
        enhanced = enhance_img_tag(site, cfg, attrs, index, wide: wide)
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
    # Prefer imagesrcset/imagesizes so preload and <img> pick the same file (#173).
    def inject_lcp_preload(html, lcp)
      href, imagesrcset, imagesizes = normalize_lcp(lcp)
      return html if href.empty?

      href_attr = escape_attr(href)
      # Already injected (or Liquid path rendered a matching preload).
      # Match both raw and entity-escaped href (& → &amp; in attributes).
      if html.match?(/rel=["']preload["']/i) && html.match?(/as=["']image["']/i) &&
         (html.include?(href) || html.include?(href_attr))
        return html
      end

      parts = [
        'rel="preload"',
        'as="image"',
        %(href="#{href_attr}")
      ]
      unless imagesrcset.empty?
        parts << %(imagesrcset="#{escape_attr(imagesrcset)}")
        parts << %(imagesizes="#{escape_attr(imagesizes)}") unless imagesizes.empty?
      end
      parts << 'fetchpriority="high"'
      tag = "<link #{parts.join(' ')}>\n"
      if html.sub!(%r{</head>}i, "#{tag}</head>")
        html
      else
        html
      end
    end

    # Layout-time Liquid may miss these hosts when image URLs are rewritten
    # here. Add the hint only if the final HTML actually fetches that origin.
    def inject_host_preconnects(html)
      return html unless html.include?("</head>")

      tags = []
      unless html.match?(%r{rel=["']preconnect["'][^>]+https://media\.jonathanfrei\.com}i)
        if html.include?("media.jonathanfrei.com")
          tags << '<link rel="preconnect" href="https://media.jonathanfrei.com" crossorigin>'
        end
      end
      return html if tags.empty?

      html.sub(%r{</head>}i, "#{tags.join("\n")}\n</head>")
    end

    def process_document(doc)
      site = doc.site
      return unless doc.respond_to?(:output) && doc.output

      new_html, lcp = process_html(site, doc.output)
      if lcp
        href, imagesrcset, imagesizes = normalize_lcp(lcp)
        doc.data["lcp_image"] = href unless href.empty?
        doc.data["lcp_imagesrcset"] = imagesrcset unless imagesrcset.empty?
        doc.data["lcp_imagesizes"] = imagesizes unless imagesizes.empty?
      end
      if new_html.include?("</head>")
        new_html = inject_lcp_preload(new_html, lcp) if lcp
        new_html = inject_host_preconnects(new_html)
      end
      doc.output = new_html
    end

    def html_with_img?(doc)
      return false if doc.output_ext && doc.output_ext != ".html"

      output = doc.output.to_s
      output.include?("<img") || output.include?("<IMG")
    end
  end
end

Jekyll::Hooks.register :site, :after_init do |_site|
  Jekyll::OptimizeContentImages.reset_caches!
end

Jekyll::Hooks.register :documents, :post_render do |doc|
  # Collection docs (posts + links). Skip feeds/assets and pages with no <img>.
  next unless Jekyll::OptimizeContentImages.html_with_img?(doc)

  Jekyll::OptimizeContentImages.process_document(doc)
end

Jekyll::Hooks.register :pages, :post_render do |page|
  next unless Jekyll::OptimizeContentImages.html_with_img?(page)

  Jekyll::OptimizeContentImages.process_document(page)
end
