# frozen_string_literal: true

require "cgi"
require "fileutils"
require "json"

# Keep old UTC permalinks working after timezone: America/New_York (#180).
#
# Production builds used to run in UTC with no site timezone. A front-matter
# date of 2026-08-12T21:17:00-04:00 became /2026/08/13/slug. After the site
# timezone is set, that post correctly lives at /2026/08/12/slug. Write a
# noindex HTML redirect at the previous UTC path so existing links resolve.
module Jekyll
  module DateRedirects
    module_function

    def write!(site)
      count = 0
      seen = {}

      site.posts.docs.each do |post|
        from = utc_url(post)
        to = post.url.to_s
        next if from.nil? || from.empty? || from == to
        next if seen.key?(from)

        dest = dest_file(site, from)
        next if dest.nil?
        if File.exist?(dest)
          Jekyll.logger.warn "DateRedirects:", "skip #{from} (already exists)"
          next
        end

        seen[from] = true
        FileUtils.mkdir_p(File.dirname(dest))
        File.write(dest, redirect_html(site, to))
        count += 1
      end

      Jekyll.logger.info "DateRedirects:", "wrote #{count} UTC permalink redirect#{'s' unless count == 1}"
    end

    # Previous permalink if :year/:month/:day had been taken from UTC.
    def utc_url(post)
      url = post.url.to_s
      date = post.date
      return url unless date.respond_to?(:year)

      local = format("/%04d/%02d/%02d/", date.year, date.month, date.day)
      utc_t = date.getutc
      utc = format("/%04d/%02d/%02d/", utc_t.year, utc_t.month, utc_t.day)
      return url if local == utc
      return url unless url.include?(local)

      url.sub(local, utc)
    end

    def dest_file(site, url)
      rel = url.sub(%r{\A/}, "").sub(%r{/\z}, "")
      return nil if rel.empty?

      File.join(site.dest, "#{rel}.html")
    end

    def redirect_html(site, to_path)
      href = absolute_url(site, to_path)
      safe = CGI.escapeHTML(href)
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <title>Redirecting…</title>
          <meta name="robots" content="noindex">
          <link rel="canonical" href="#{safe}">
          <meta http-equiv="refresh" content="0;url=#{safe}">
          <script>location.replace(#{href.to_json});</script>
        </head>
        <body>
          <p>This page has moved to <a href="#{safe}">#{safe}</a>.</p>
        </body>
        </html>
      HTML
    end

    def absolute_url(site, path)
      base = site.config["url"].to_s.chomp("/")
      prefix = site.config["baseurl"].to_s.chomp("/")
      path = "/#{path}" unless path.start_with?("/")
      "#{base}#{prefix}#{path}"
    end
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::DateRedirects.write!(site)
end
