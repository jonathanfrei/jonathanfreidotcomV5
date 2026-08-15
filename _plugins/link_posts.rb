# frozen_string_literal: true

# Link posts are normal _posts/ with layout: link and a destination url:.
# This hook copies url → external_url/host and resolves the on-site card.
require "cgi"
require "digest"
require "fileutils"
require "ipaddr"
require "json"
require "net/http"
require "socket"
require "uri"

module Jekyll
  module LinkPosts
    module_function

    FETCH_TIMEOUT = 4
    MAX_BODY_BYTES = 512 * 1024
    MAX_REDIRECTS = 3

    def link_post?(doc)
      doc.data["layout"].to_s == "link" || doc.data["type"].to_s == "link"
    end

    def prepare_post!(site, doc)
      return unless link_post?(doc)

      doc.data["layout"] = "link"
      doc.data["type"] = "link"

      cats = Array(doc.data["categories"]).map(&:to_s)
      unless cats.any? { |c| c.downcase == "links" }
        cats << "links"
        doc.data["categories"] = cats
      end

      raw = doc.data["url"].to_s
      if blank?(raw)
        BuildErrors.record(site, doc.relative_path, "`url` is required on link posts")
        return
      end

      begin
        uri = public_url!(raw, doc.relative_path)
      rescue Jekyll::Errors::FatalException => e
        BuildErrors.record(site, doc.relative_path, e.message)
        return
      end

      doc.data["external_url"] = uri.to_s
      doc.data["host"] = uri.host
      resolve_card!(site, doc)
    end

    def resolve_card!(site, doc)
      source = doc.data["card"]
      if source == false
        doc.data.delete("card")
        return
      end

      if source.is_a?(Hash)
        supplied = source.transform_keys(&:to_s)
        card = utf8_hash(supplied.compact)
        card["url"] = doc.data["external_url"]
        card["host"] = doc.data["host"]
        card["title"] ||= doc.data["title"]
        absolutize_card_image!(card, doc.data["external_url"])
        doc.data["card"] = card
        return
      end

      unless source.nil?
        BuildErrors.record(site, doc.relative_path, "card must be false or a mapping")
        return
      end

      fetched = fetch_metadata(site, doc.data["external_url"])
      return if fetched.empty?

      fetched["url"] = doc.data["external_url"]
      fetched["host"] = doc.data["host"]
      fetched["title"] ||= doc.data["title"]
      absolutize_card_image!(fetched, doc.data["external_url"])
      doc.data["card"] = utf8_hash(fetched)
    end

    def absolutize_card_image!(card, base_url)
      image = card["image"].to_s
      return if image.empty? || image.match?(%r{\Ahttps?://}i)

      card["image"] = URI.join(base_url.to_s, image).to_s
    rescue URI::InvalidURIError
      nil
    end

    def fetch_metadata(site, raw_url)
      cached = read_card_cache(site, raw_url)
      return cached if cached

      uri = public_url!(raw_url, "link card")
      response = get_with_redirects(uri)
      return {} unless response.is_a?(Net::HTTPSuccess)

      html = utf8(response.body.to_s.byteslice(0, MAX_BODY_BYTES))
      metadata = metadata_from_html(html)
      write_card_cache(site, raw_url, metadata)
      metadata
    rescue StandardError => e
      Jekyll.logger.warn "LinkPosts:", "card metadata unavailable for #{raw_url} (#{e.class}: #{e.message})"
      {}
    end

    def cache_dir(site)
      File.join(site.source, ".jekyll-cache", "link-cards")
    end

    def cache_path(site, raw_url)
      File.join(cache_dir(site), "#{Digest::SHA256.hexdigest(raw_url)}.json")
    end

    def read_card_cache(site, raw_url)
      path = cache_path(site, raw_url)
      return unless File.file?(path)

      data = JSON.parse(File.read(path))
      data.is_a?(Hash) ? utf8_hash(data) : nil
    rescue JSON::ParserError
      nil
    end

    def write_card_cache(site, raw_url, metadata)
      dir = cache_dir(site)
      FileUtils.mkdir_p(dir)
      File.write(cache_path(site, raw_url), JSON.pretty_generate(metadata))
    rescue StandardError
      nil
    end

    def get_with_redirects(uri, remaining = MAX_REDIRECTS)
      raise "too many redirects" if remaining.negative?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = FETCH_TIMEOUT
      http.read_timeout = FETCH_TIMEOUT
      request = Net::HTTP::Get.new(
        uri.request_uri.empty? ? "/" : uri.request_uri,
        { "User-Agent" => "jonathanfrei.com link-preview/1.0" }
      )
      response = http.request(request)
      return response unless response.is_a?(Net::HTTPRedirection)

      location = response["location"]
      raise "redirect without location" if location.to_s.empty?

      get_with_redirects(public_url!(URI.join(uri, location).to_s, "link card redirect"), remaining - 1)
    end

    def metadata_from_html(html)
      values = {}
      html.to_s.scan(/<meta\b[^>]*>/i).each do |tag|
        key = attribute(tag, "property") || attribute(tag, "name")
        value = attribute(tag, "content")
        next if key.to_s.empty? || value.to_s.empty?

        values[key.downcase] ||= utf8(CGI.unescapeHTML(value.strip))
      end
      title = values["og:title"] || html.to_s[/<title\b[^>]*>(.*?)<\/title>/im, 1]
      utf8_hash(
        {
          "title" => title && CGI.unescapeHTML(title.gsub(/\s+/, " ").strip),
          "description" => values["og:description"] || values["description"],
          "image" => values["og:image"],
          "image_alt" => values["og:image:alt"],
          "site_name" => values["og:site_name"]
        }.reject { |_key, value| value.nil? || value.empty? }
      )
    end

    def attribute(tag, name)
      tag[/\b#{Regexp.escape(name)}\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/i, 1] ||
        tag[/\b#{Regexp.escape(name)}\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/i, 2] ||
        tag[/\b#{Regexp.escape(name)}\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/i, 3]
    end

    def public_url!(raw, label)
      uri = URI.parse(raw.to_s)
      unless %w[http https].include?(uri.scheme) && uri.host && uri.userinfo.nil?
        raise Jekyll::Errors::FatalException, "#{label}: URL must be a public http(s) URL"
      end
      raise Jekyll::Errors::FatalException, "#{label}: URL host must not resolve to a private address" if private_host?(uri.host)

      uri
    rescue URI::InvalidURIError
      raise Jekyll::Errors::FatalException, "#{label}: invalid URL"
    end

    def private_host?(host)
      return true if host.casecmp?("localhost") || host.end_with?(".local")

      Addrinfo.getaddrinfo(host, nil, nil, Socket::SOCK_STREAM).any? do |addr|
        ip = IPAddr.new(addr.ip_address)
        ip.loopback? || ip.private? || ip.link_local? || unspecified_ip?(ip) || multicast_ip?(ip)
      end
    rescue SocketError
      false
    end

    def unspecified_ip?(ip)
      return ip.unspecified? if ip.respond_to?(:unspecified?)

      ip == IPAddr.new("0.0.0.0") || ip == IPAddr.new("::")
    end

    def multicast_ip?(ip)
      return ip.multicast? if ip.respond_to?(:multicast?)

      (ip.ipv4? && ((ip.to_i >> 28) == 0xE)) || (ip.ipv6? && ((ip.to_i >> 120) == 0xFF))
    end

    def blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?) || value.to_s.strip.empty?
    end

    def utf8(value)
      return value unless value.is_a?(String)

      string = value.dup
      string.force_encoding(Encoding::UTF_8)
      return string if string.valid_encoding?

      string.force_encoding(Encoding::ASCII_8BIT)
            .encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    end

    def utf8_hash(hash)
      hash.transform_values { |value| utf8(value) }
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.posts.docs.each { |post| Jekyll::LinkPosts.prepare_post!(site, post) }
  Jekyll::NormalizeTags.reset_caches!(site) if defined?(Jekyll::NormalizeTags)
end
