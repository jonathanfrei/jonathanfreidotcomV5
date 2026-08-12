# frozen_string_literal: true

require "cgi"

# Historical posts under _posts/v{1,2,3}-archive/ use relative media paths like
# ![](media/12345.jpg) or src="media/2015/09/photo.jpg". With directory-style
# permalinks those resolve under the post URL (e.g. /photos/…/media/…), which
# is wrong.
#
# Production source of truth is the S3 bucket behind media.jonathanfrei.com
# (issue #170; previously jsDelivr from in-repo files, #68):
#   https://media.jonathanfrei.com/v2-archive/media/100012152738.gif
#   https://media.jonathanfrei.com/v3-archive/media/2015/01/IMG_6861.jpg
#
# At build time:
#   1. Rewrite content URLs so images load correctly
#   2. In CDN mode (default for production): point at S3 and do NOT copy media
#      into the GitHub Pages artifact (deploy-pages 10-minute hard cap).
#   3. In local mode (optional): if media still exists under
#      _posts/v*-archive/media/, publish referenced files under /media/ for
#      offline `jekyll serve`. Prefer CDN once the repo media trees are removed.
#
# Also strip folder-derived categories (v1-archive, v2-archive, v3-archive) so
# those segments do not appear in URLs. Explicit front-matter categories
# (e.g. photos, blog on v3 posts) are preserved.
#
# Config (_config.yml):
#   archive_media:
#     mode: auto   # auto | cdn | local  (auto → cdn when JEKYLL_ENV=production)
#     cdn_base: "https://media.jonathanfrei.com"
module Jekyll
  class ArchiveMediaFile < StaticFile
    def initialize(site, base, dir, name, dest_dir)
      super(site, base, dir, name)
      @dest_dir = dest_dir
    end

    def destination(dest)
      File.join(dest, @dest_dir, @name)
    end

    # Include site.baseurl so project-pages deploys resolve correctly.
    def url
      path = "/#{File.join(@dest_dir, @name).gsub(%r{/+}, '/')}"
      if @site.baseurl && !@site.baseurl.empty?
        "#{@site.baseurl.chomp('/')}#{path}"
      else
        path
      end
    end

    def relative_path
      File.join(@dest_dir, @name)
    end
  end

  module FixArchiveMedia
    ARCHIVE_PREFIXES = %w[
      _posts/v1-archive/
      _posts/v2-archive/
      _posts/v3-archive/
    ].freeze
    MEDIA_SOURCE_DIRS = %w[
      _posts/v1-archive/media
      _posts/v2-archive/media
      _posts/v3-archive/media
    ].freeze
    FOLDER_CATEGORIES = %w[v1-archive v2-archive v3-archive].freeze
    # Capture relative path after media/ for markdown links and HTML src/href.
    MEDIA_REF = %r{(?:\]\(|(?:src|href)=(["']))media/([^)"'\s]+)}.freeze
    # Public object prefix on S3 (no _posts/ segment).
    ARCHIVE_SLUG_RE = %r{\A_posts/(v[123]-archive)/}.freeze
    DEFAULT_CDN_BASE = "https://media.jonathanfrei.com".freeze

    module_function

    def archive_post?(path)
      ARCHIVE_PREFIXES.any? { |prefix| path.start_with?(prefix) }
    end

    # "_posts/v2-archive/2010-01-01-slug.md" → "v2-archive"
    def archive_slug_for_post(path)
      m = path.to_s.match(ARCHIVE_SLUG_RE)
      m && m[1]
    end

    # Drop only the folder-name categories Jekyll derives from _posts subdirs.
    # Keep intentional front-matter categories (photos, blog, links, …).
    def clear_folder_categories!(post)
      cats = Array(post.data["categories"]).map(&:to_s)
      post.data["categories"] = cats.reject { |c| FOLDER_CATEGORIES.include?(c) }
    end

    def config(site)
      site.config["archive_media"] || {}
    end

    # auto → cdn in production builds, local otherwise (when media still on disk)
    def mode(site)
      raw = ENV["ARCHIVE_MEDIA_MODE"].to_s.strip
      raw = config(site)["mode"].to_s.strip if raw.empty?
      raw = "auto" if raw.empty?

      case raw.downcase
      when "cdn", "remote"
        "cdn"
      when "local", "bundle"
        "local"
      else
        # auto: production always CDN; local serve uses files if present else CDN
        if Jekyll.env == "production"
          "cdn"
        elsif local_media_available?(site)
          "local"
        else
          "cdn"
        end
      end
    end

    def local_media_available?(site)
      MEDIA_SOURCE_DIRS.any? { |d| File.directory?(File.join(site.source, d)) }
    end

    def cdn_base(site)
      base = ENV["ARCHIVE_MEDIA_CDN_BASE"].to_s.strip
      base = config(site)["cdn_base"].to_s.strip if base.empty?
      base = DEFAULT_CDN_BASE if base.empty?
      base.chomp("/")
    end

    # Map relative media path (e.g. "2014/10/photo.jpg") → absolute source dir
    # under site.source (e.g. "_posts/v3-archive/media"). First match wins.
    # Only used for local bundling and optional dimension lookups while files
    # remain in the repo; CDN URLs do not require this index (#170).
    def media_index(site)
      @media_index_cache ||= {}
      key = site.source
      return @media_index_cache[key] if @media_index_cache[key]

      index = {}
      MEDIA_SOURCE_DIRS.each do |src_dir|
        abs = File.join(site.source, src_dir)
        next unless File.directory?(abs)

        Dir.chdir(abs) do
          Dir.glob("**/*", File::FNM_DOTMATCH).each do |rel|
            next unless File.file?(rel)
            # Normalize separators for Windows checkouts
            rel_n = rel.tr("\\", "/")
            index[rel_n] ||= src_dir
          end
        end
      end

      @media_index_cache[key] = index
    end

    def encode_cdn_path(path)
      path.split("/").map { |seg| CGI.escape(seg).gsub("+", "%20") }.join("/")
    end

    # Absolute CDN URL for a media object under an archive slug.
    # archive_slug: "v2-archive" → https://media…/v2-archive/media/{rel}
    # Does not require the file to exist in the local repo (#170).
    def cdn_url_for(site, rel, archive_slug: nil)
      rel_n = rel.to_s.sub(%r{\A/+}, "").split("?").first.to_s.tr("\\", "/")
      return nil if rel_n.empty?

      slug = archive_slug.to_s.strip
      if slug.empty?
        src_dir = media_index(site)[rel_n]
        if src_dir && (m = src_dir.match(%r{\A_posts/(v[123]-archive)/media\z}))
          slug = m[1]
        end
      end
      return nil if slug.empty?

      "#{cdn_base(site)}/#{encode_cdn_path("#{slug}/media/#{rel_n}")}"
    end

    def local_media_url(rel, baseurl = "")
      prefix = baseurl.to_s.chomp("/")
      "#{prefix}/media/#{rel.sub(%r{\A/+}, "")}"
    end

    # Resolve one media/… reference to either a CDN URL or site-local /media/ URL.
    def resolve_media_url(site, rel, baseurl, mode_name, archive_slug: nil)
      rel_n = rel.to_s.sub(%r{\A/+}, "").split("?").first.to_s.tr("\\", "/")
      return local_media_url(rel_n, baseurl) if rel_n.empty?

      if mode_name == "cdn"
        cdn = cdn_url_for(site, rel_n, archive_slug: archive_slug)
        return cdn if cdn

        Jekyll.logger.warn(
          "FixArchiveMedia:",
          "cannot build CDN URL (unknown archive) for media/#{rel_n}"
        )
        return local_media_url(rel_n, baseurl)
      end

      # Local mode: prefer on-disk file; fall back to CDN if this object is
      # already only on S3 (partial migration).
      if media_index(site)[rel_n]
        local_media_url(rel_n, baseurl)
      else
        cdn = cdn_url_for(site, rel_n, archive_slug: archive_slug)
        return cdn if cdn

        local_media_url(rel_n, baseurl)
      end
    end

    # Markdown images/links: ](media/…) → ](resolved)
    # HTML src/href: src="media/…" → src="resolved"
    # Leave absolute http(s) and already-rooted paths alone.
    def rewrite_media_paths!(text, site, baseurl = "", archive_slug: nil)
      return text if text.nil? || text.empty?

      mode_name = mode(site)

      text
        .gsub(%r{\]\(media/([^)\s]+)}) do
          rel = Regexp.last_match(1)
          "](#{resolve_media_url(site, rel, baseurl, mode_name, archive_slug: archive_slug)}"
        end
        .gsub(%r{(src|href)=(["'])media/([^"']+)\2}) do
          attr = Regexp.last_match(1)
          quote = Regexp.last_match(2)
          rel = Regexp.last_match(3)
          "#{attr}=#{quote}#{resolve_media_url(site, rel, baseurl, mode_name, archive_slug: archive_slug)}#{quote}"
        end
    end

    def referenced_media_paths(site)
      paths = {}
      site.posts.docs.each do |post|
        next unless archive_post?(post.relative_path)

        content = post.content.to_s
        content.scan(MEDIA_REF) do
          rel = Regexp.last_match(2).to_s.split("?").first.to_s
          rel = rel.sub(%r{\A/+}, "").tr("\\", "/")
          next if rel.empty?

          paths[rel] = true
        end
      end
      paths
    end

    # Local mode only: publish referenced media under /media/ for jekyll serve.
    # CDN mode deliberately skips this so the Pages artifact stays tiny.
    def register_media_static_files!(site)
      mode_name = mode(site)
      if mode_name == "cdn"
        needed = referenced_media_paths(site)
        Jekyll.logger.info(
          "FixArchiveMedia:",
          "cdn mode — #{needed.size} media reference(s) → #{cdn_base(site)} " \
          "(not bundled in _site)"
        )
        return
      end

      needed = referenced_media_paths(site)
      return if needed.empty?

      registered = {}
      MEDIA_SOURCE_DIRS.each do |src_dir|
        abs = File.join(site.source, src_dir)
        next unless File.directory?(abs)

        needed.each_key do |rel|
          next if registered[rel]

          full = File.join(abs, rel)
          next unless File.file?(full)

          dir = File.dirname(rel)
          name = File.basename(rel)
          relative_dir = (dir == "." ? "" : dir)
          dest_dir = relative_dir.empty? ? "media" : File.join("media", relative_dir)

          site.static_files << Jekyll::ArchiveMediaFile.new(
            site,
            abs,
            relative_dir,
            name,
            dest_dir
          )
          registered[rel] = true
        end
      end

      missing = needed.size - registered.size
      msg = "local mode — publishing #{registered.size}/#{needed.size} media " \
            "file(s) under /media/"
      msg += " (#{missing} missing locally → CDN fallback at rewrite)" if missing.positive?
      Jekyll.logger.info("FixArchiveMedia:", msg)
    end
  end
end

Jekyll::Hooks.register :posts, :post_init do |post|
  next unless Jekyll::FixArchiveMedia.archive_post?(post.relative_path)

  Jekyll::FixArchiveMedia.clear_folder_categories!(post)
end

Jekyll::Hooks.register :posts, :pre_render do |post|
  next unless Jekyll::FixArchiveMedia.archive_post?(post.relative_path)

  baseurl = post.site.baseurl || ""
  slug = Jekyll::FixArchiveMedia.archive_slug_for_post(post.relative_path)
  post.content = Jekyll::FixArchiveMedia.rewrite_media_paths!(
    post.content, post.site, baseurl, archive_slug: slug
  )
  if post.data["excerpt"] && post.data["excerpt"].respond_to?(:content)
    post.data["excerpt"].content =
      Jekyll::FixArchiveMedia.rewrite_media_paths!(
        post.data["excerpt"].content, post.site, baseurl, archive_slug: slug
      )
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  Jekyll::FixArchiveMedia.register_media_static_files!(site)
end
