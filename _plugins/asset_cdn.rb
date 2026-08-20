# frozen_string_literal: true

# Serve /assets from jsDelivr's GitHub CDN in production.
#
# Generated CSS (core.css / editorial.css / book.css) is not in git at those permalinks,
# so those public paths map to the include files jsDelivr can fetch.
# JS and images under assets/ are served from their repo paths.
#
# Pin the URL to the build commit (GITHUB_SHA, or git HEAD) so a deploy is
# not stuck behind jsDelivr's @main cache. Origin copies still write to
# _site/assets. Templates attach data-fallback + assetFallback() so a
# GitHub/jsDelivr miss still loads /assets from Pages.
#
# Config (_config.yml):
#   assets_cdn:
#     enabled: auto   # auto | true | false  (auto → on when JEKYLL_ENV=production)
#     host: "https://cdn.jsdelivr.net"
#     repo: "jonathanfrei/jonathanfreidotcomV5"
#     ref: ""         # optional override (commit SHA, tag, or branch)
# Override with ASSETS_CDN=on|off.
module Jekyll
  module AssetCdn
    module_function

    DEFAULTS = {
      "enabled" => "auto",
      "host" => "https://cdn.jsdelivr.net",
      "repo" => "jonathanfrei/jonathanfreidotcomV5",
      "ref" => ""
    }.freeze

    # Public permalink → file path in the git repo (jsDelivr cannot see _site).
    SOURCE_MAP = {
      "/assets/css/core.css" => "_includes/main.css",
      "/assets/css/editorial.css" => "_includes/editorial.css",
      "/assets/css/book.css" => "_includes/book.css"
    }.freeze

    def config(site)
      DEFAULTS.merge(site.config["assets_cdn"] || {})
    end

    def enabled?(site)
      @enabled_cache ||= {}
      key = site.object_id
      return @enabled_cache[key] if @enabled_cache.key?(key)

      env = ENV["ASSETS_CDN"].to_s.strip.downcase
      @enabled_cache[key] =
        if %w[0 false off local].include?(env)
          false
        elsif %w[1 true on cdn].include?(env)
          true
        else
          mode = config(site)["enabled"].to_s
          if %w[false off 0].include?(mode)
            false
          elsif %w[true on 1].include?(mode)
            true
          else
            ENV["JEKYLL_ENV"].to_s == "production"
          end
        end
    end

    def ref(site)
      @ref_cache ||= {}
      key = site.object_id
      return @ref_cache[key] if @ref_cache.key?(key)

      explicit = config(site)["ref"].to_s.strip
      @ref_cache[key] =
        if !explicit.empty?
          explicit
        elsif sha?(ENV["GITHUB_SHA"].to_s.strip)
          ENV["GITHUB_SHA"].to_s.strip
        else
          from_git = `git rev-parse HEAD`.to_s.strip
          sha?(from_git) ? from_git : "main"
        end
    end

    def reset_caches!
      @enabled_cache = {}
      @ref_cache = {}
    end

    def sha?(value)
      value.match?(/\A[0-9a-f]{7,40}\z/)
    end

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

    def origin_url(site, path)
      href = public_path(path)
      query = path.to_s[/\?.*\z/]
      base = site.config["baseurl"].to_s
      base = "" if base == "/"
      base = base.sub(%r{/\z}, "")
      "#{base}#{href}#{query}"
    end

    def cdn_url(site, path)
      cfg = config(site)
      host = cfg["host"].to_s.sub(%r{/\z}, "")
      repo = cfg["repo"].to_s
      "#{host}/gh/#{repo}@#{ref(site)}/#{repo_path(path)}"
    end

    def url(site, path)
      return origin_url(site, path) unless enabled?(site)

      cdn_url(site, path)
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
      if AssetCdn.enabled?(site)
        Jekyll.logger.info "AssetCdn:",
                           "jsDelivr gh/#{AssetCdn.config(site)['repo']}@" \
                           "#{AssetCdn.ref(site)}"
      else
        Jekyll.logger.info "AssetCdn:", "origin /assets (local)"
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::AssetCdnFilter)
