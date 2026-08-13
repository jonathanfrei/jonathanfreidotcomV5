# frozen_string_literal: true

# Link posts (#37): one Markdown file per link under _links/.
# Filename stem yyyy-mm-dd-hh-mm is the permalink (/yyyy-mm-dd-hh-mm).
# Subfolders are allowed and do not affect the URL.
require "cgi"
require "digest"
require "fileutils"
require "ipaddr"
require "json"
require "net/http"
require "socket"
require "time"
require "uri"

module Jekyll
  module LinkPosts
    module_function

    REQUIRED = %w[title url date].freeze
    FILENAME = /\A\d{4}-\d{2}-\d{2}-\d{2}-\d{2}\z/
    FETCH_TIMEOUT = 4
    MAX_BODY_BYTES = 512 * 1024
    MAX_REDIRECTS = 3
    FEED_LIMIT = 40

    def prepare!(site)
      collection = site.collections["links"]
      return [] unless collection

      docs = collection.docs
      docs.each { |doc| normalize_doc!(site, doc) }
      assert_unique_slugs!(docs)
      assert_no_path_collisions!(site, docs)
      docs.each { |doc| resolve_card!(site, doc) }
      docs.sort_by { |doc| doc.data["date_sort"] }.reverse
    end

    def normalize_doc!(site, doc)
      stem = File.basename(doc.path, ".*")
      unless stem.match?(FILENAME)
        raise Jekyll::Errors::FatalException,
              "#{doc.relative_path}: link files must be named yyyy-mm-dd-hh-mm.md"
      end

      type = doc.data["type"].to_s
      type = "link" if type.empty?
      unless type == "link"
        raise Jekyll::Errors::FatalException,
              "#{doc.relative_path}: type must be \"link\" (got #{type.inspect})"
      end

      REQUIRED.each do |field|
        if blank?(doc.data[field])
          raise Jekyll::Errors::FatalException,
                "#{doc.relative_path}: `#{field}` is required"
        end
      end

      assert_timezone!(doc)
      date = coerce_time(doc.data["date"])
      unless date
        raise Jekyll::Errors::FatalException, "#{doc.relative_path}: date must be parseable"
      end

      stamp = date.getlocal(date.utc_offset).strftime("%Y-%m-%d-%H-%M")
      unless stamp == stem
        Jekyll.logger.warn "LinkPosts:",
                           "#{doc.relative_path}: filename #{stem} does not match date #{stamp}"
      end

      url = public_url!(doc.data["url"], doc.relative_path)
      tags = Array(doc.data["tags"]).map(&:to_s).reject(&:empty?)
      excerpt = doc.data["excerpt"].to_s
      description = doc.data["description"].to_s
      description = excerpt if description.empty?

      doc.data["type"] = "link"
      doc.data["slug"] = stem
      doc.data["permalink"] = "/#{stem}"
      doc.instance_variable_set(:@url, nil)
      doc.data["external_url"] = url.to_s
      doc.data["host"] = url.host
      doc.data["date"] = date
      doc.data["date_sort"] = date.utc.iso8601
      doc.data["date_xml"] = date.xmlschema
      doc.data["year"] = date.getlocal(date.utc_offset).strftime("%Y")
      doc.data["month"] = date.getlocal(date.utc_offset).strftime("%m")
      doc.data["tags"] = tags
      doc.data["excerpt"] = excerpt
      doc.data["description"] = description unless description.empty?
    end

    def assert_timezone!(doc)
      raw = raw_front_matter_date(doc)
      return if raw.nil?
      return if raw.match?(/(?:Z|[+-]\d{2}:?\d{2})\s*\z/)

      raise Jekyll::Errors::FatalException,
            "#{doc.relative_path}: date must include a timezone"
    end

    def raw_front_matter_date(doc)
      text = File.read(doc.path)
      return unless text =~ /\A---\s*\n(.*?)\n---\s*\n/m

      front = Regexp.last_match(1)
      line = front.lines.find { |l| l.start_with?("date:") }
      return unless line

      line.sub(/\Adate:\s*/, "").strip.gsub(/\A["']|["']\z/, "")
    rescue StandardError
      nil
    end

    def coerce_time(value)
      case value
      when Time then value
      when DateTime then value.to_time
      when Date then value.to_time
      else
        Time.parse(value.to_s)
      end
    rescue ArgumentError
      nil
    end

    def assert_unique_slugs!(docs)
      grouped = docs.group_by { |doc| doc.data["slug"] }
      duplicate = grouped.find { |_slug, list| list.size > 1 }
      return unless duplicate

      paths = duplicate.last.map(&:relative_path).join(", ")
      raise Jekyll::Errors::FatalException,
            "duplicate link filename stem `#{duplicate.first}`: #{paths}"
    end

    def assert_no_path_collisions!(site, docs)
      taken = {}
      site.posts.docs.each { |post| taken[normalize_url(post.url)] = post.relative_path }
      site.pages.each { |page| taken[normalize_url(page.url)] = page.relative_path }

      docs.each do |doc|
        key = normalize_url(doc.data["permalink"])
        if taken[key]
          raise Jekyll::Errors::FatalException,
                "#{doc.relative_path}: permalink #{doc.data['permalink']} collides with #{taken[key]}"
        end
        taken[key] = doc.relative_path
      end
    end

    def normalize_url(url)
      url.to_s.sub(%r{/\z}, "").sub(/\.html\z/, "")
    end

    def resolve_card!(site, doc)
      source = doc.data["card"]
      if source == false
        doc.data.delete("card")
        return
      end

      if source.is_a?(Hash)
        supplied = source.transform_keys(&:to_s)
        card = supplied.compact
        card["url"] = doc.data["external_url"]
        card["host"] = doc.data["host"]
        card["title"] ||= doc.data["title"]
        doc.data["card"] = card
        return
      end

      unless source.nil?
        raise Jekyll::Errors::FatalException,
              "#{doc.relative_path}: card must be false or a mapping"
      end

      fetched = fetch_metadata(site, doc.data["external_url"])
      return if fetched.empty?

      fetched["url"] = doc.data["external_url"]
      fetched["host"] = doc.data["host"]
      fetched["title"] ||= doc.data["title"]
      doc.data["card"] = fetched
    end

    def fetch_metadata(site, raw_url)
      cached = read_card_cache(site, raw_url)
      return cached if cached

      uri = public_url!(raw_url, "link card")
      response = get_with_redirects(uri)
      return {} unless response.is_a?(Net::HTTPSuccess)

      html = response.body.to_s.byteslice(0, MAX_BODY_BYTES)
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
      data.is_a?(Hash) ? data : nil
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

        values[key.downcase] ||= CGI.unescapeHTML(value.strip)
      end
      title = values["og:title"] || html.to_s[/<title\b[^>]*>(.*?)<\/title>/im, 1]
      {
        "title" => title && CGI.unescapeHTML(title.gsub(/\s+/, " ").strip),
        "description" => values["og:description"] || values["description"],
        "image" => values["og:image"],
        "image_alt" => values["og:image:alt"],
        "site_name" => values["og:site_name"]
      }.reject { |_key, value| value.nil? || value.empty? }
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
        ip.loopback? || ip.private? || ip.link_local? || ip.unspecified? || ip.multicast?
      end
    rescue SocketError
      false
    end

    def blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?) || value.to_s.strip.empty?
    end

    def stream_item_for_link(doc)
      {
        "kind" => "link",
        "title" => doc.data["title"].to_s,
        "url" => doc.url,
        "internal_url" => doc.url,
        "external_url" => doc.data["external_url"],
        "host" => doc.data["host"],
        "date" => doc.data["date"],
        "date_sort" => doc.data["date_sort"],
        "date_xml" => doc.data["date_xml"],
        "excerpt" => doc.data["excerpt"].to_s,
        "description" => doc.data["description"].to_s,
        "tags" => doc.data["tags"],
        "card" => doc.data["card"],
        "year" => doc.data["year"],
        "month" => doc.data["month"]
      }
    end

    def stream_item_for_post(post)
      {
        "kind" => "post",
        "title" => post.data["title"].to_s,
        "url" => post.url,
        "internal_url" => post.url,
        "date" => post.date,
        "date_sort" => post.date.utc.iso8601,
        "date_xml" => post.date.xmlschema,
        "excerpt" => post.data["excerpt"].to_s,
        "description" => post.data["description"].to_s,
        "tags" => Array(post.data["tags"])
      }
    end
  end

  class LinkGeneratedPage < PageWithoutAFile
    def initialize(site, dir, name, data = {})
      super(site, site.source, dir, name)
      self.data = data
      self.content = ""
    end
  end

  class LinkPostsGenerator < Generator
    safe true
    priority :high

    def generate(site)
      docs = LinkPosts.prepare!(site)
      site.data["link_posts"] = docs
      site.data["link_years"] = docs.group_by { |doc| doc.data["year"] }.map do |year, year_docs|
        months = year_docs.group_by { |doc| doc.data["month"] }.keys.sort.reverse
        { "name" => year, "months" => months.map { |month| { "name" => month } } }
      end.sort_by { |entry| entry["name"] }.reverse
      stream = site.posts.docs.map { |post| LinkPosts.stream_item_for_post(post) } +
               docs.map { |doc| LinkPosts.stream_item_for_link(doc) }
      site.data["site_stream"] = stream.sort_by { |item| item["date_sort"] }.reverse

      docs.group_by { |doc| doc.data["year"] }.each do |year, year_docs|
        months = year_docs.group_by { |doc| doc.data["month"] }.map do |month, month_docs|
          sample = month_docs.first.data["date"]
          {
            "key" => month,
            "name" => sample.getlocal(sample.utc_offset).strftime("%B"),
            "url" => "/links/#{year}/#{month}/",
            "count" => month_docs.size
          }
        end.sort_by { |entry| entry["key"] }.reverse

        site.pages << LinkGeneratedPage.new(site, "links", "#{year}.html", {
          "layout" => "link_archive",
          "permalink" => "/links/#{year}",
          "title" => "Links from #{year}",
          "description" => "Links published in #{year}.",
          "year" => year,
          "months" => months,
          "link_entries" => year_docs.sort_by { |doc| doc.data["date_sort"] }.reverse
        })

        year_docs.group_by { |doc| doc.data["month"] }.each do |month, month_docs|
          sample = month_docs.first.data["date"]
          month_name = sample.getlocal(sample.utc_offset).strftime("%B")
          site.pages << LinkGeneratedPage.new(site, "links/#{year}/#{month}", "index.html", {
            "layout" => "link_archive",
            "permalink" => "/links/#{year}/#{month}/",
            "title" => "Links from #{month_name} #{year}",
            "description" => "Links published in #{month_name} #{year}.",
            "year" => year,
            "month" => month,
            "month_name" => month_name,
            "link_entries" => month_docs.sort_by { |doc| doc.data["date_sort"] }.reverse
          })
        end
      end
    end
  end
end
