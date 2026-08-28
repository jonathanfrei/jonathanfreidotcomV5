# frozen_string_literal: true

require "digest"

# Fingerprint /assets URLs so Cloudflare's long browser TTL cannot serve a
# stale design-system file after a CSS/JS change. Purge-on-deploy only
# clears the edge, not the browser.
#
# Generated CSS (core.css / editorial.css / book.css) is not in git at those
# permalinks, so the hash is taken from the include file that is the source.
# JS and images under assets/ hash their repo files.
#
# jsDelivr offload was removed: HTML is already on Cloudflare, and a second
# origin on render-blocking CSS/fonts is a net loss. ASSETS_CDN is ignored.
module Jekyll
  module AssetCdn
    module_function

    # Public permalink → file path in the git repo (the published CSS files
    # are generated; hash the includes they copy).
    SOURCE_MAP = {
      "/assets/css/core.css" => "_includes/main.css",
      "/assets/css/editorial.css" => "_includes/editorial.css",
      "/assets/css/book.css" => "_includes/book.css"
    }.freeze

    def public_path(path)
      href = path.to_s.strip
      href = href.split("?", 2).first.to_s
      href = "/#{href}" unless href.start_with?("/")
      href
    end

    def repo_path(path)
      href = public_path(path)
      SOURCE_MAP.fetch(href) { href.sub(%r{\A/}, "") }
    end

    def digest(site, path)
      @digest_cache ||= {}
      href = public_path(path)
      key = [site.object_id, href]
      return @digest_cache[key] if @digest_cache.key?(key)

      file = File.join(site.source, repo_path(href))
      @digest_cache[key] =
        if File.file?(file)
          Digest::SHA256.file(file).hexdigest[0, 12]
        else
          ref(site)[0, 12]
        end
    end

    def ref(site)
      @ref_cache ||= {}
      key = site.object_id
      return @ref_cache[key] if @ref_cache.key?(key)

      if sha?(ENV["GITHUB_SHA"].to_s.strip)
        @ref_cache[key] = ENV["GITHUB_SHA"].to_s.strip
      else
        from_git = `git rev-parse HEAD`.to_s.strip
        @ref_cache[key] = sha?(from_git) ? from_git : "dev"
      end
    end

    def reset_caches!
      @digest_cache = {}
      @ref_cache = {}
    end

    def sha?(value)
      value.match?(/\A[0-9a-f]{7,40}\z/)
    end

    def origin_url(site, path)
      href = public_path(path)
      extra = path.to_s.split("?", 2)[1].to_s
      extra_parts = extra.split("&").reject { |part| part.empty? || part.start_with?("v=") }
      base = site.config["baseurl"].to_s
      base = "" if base == "/"
      base = base.sub(%r{/\z}, "")
      query = (["v=#{digest(site, href)}"] + extra_parts).join("&")
      "#{base}#{href}?#{query}"
    end

    def url(site, path)
      origin_url(site, path)
    end
  end

  module AssetCdnFilter
    def asset_url(input)
      site = @context.registers[:site]
      Jekyll::AssetCdn.url(site, input)
    end

    def asset_origin_url(input)
      site = @context.registers[:site]
      Jekyll::AssetCdn.origin_url(site, input)
    end
  end

  class AssetCdnLogger < Generator
    safe true
    priority :lowest

    def generate(site)
      Jekyll.logger.info "AssetCdn:", "origin /assets with content-hash ?v="
    end
  end
end

Liquid::Template.register_filter(Jekyll::AssetCdnFilter)
