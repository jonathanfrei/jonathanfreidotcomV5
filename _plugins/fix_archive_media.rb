# frozen_string_literal: true

# Historical posts under _posts/v{1,2,3}-archive/ use relative media paths like
# ![](media/12345.jpg) or src="media/2015/09/photo.jpg". With directory-style
# permalinks those resolve under the post URL (e.g. /photos/…/media/…), which
# is wrong.
#
# Leave media files where they are in the repo (_posts/v2-archive/media/ etc.).
# At build time:
#   1. Rewrite content URLs: media/… → #{baseurl}/media/…
#   2. Publish only *referenced* media files under /media/ (keeps the Pages
#      artifact smaller so deploy-pages stays under its 10-minute timeout)
#
# Also strip folder-derived categories (v1-archive, v2-archive, v3-archive) so
# those segments do not appear in URLs. Explicit front-matter categories
# (e.g. photos, blog on v3 posts) are preserved.
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
    MEDIA_REF = %r{(?:\]\(|(?:src|href)=(["']))media/([^)"'\s]+)}.freeze

    module_function

    def archive_post?(path)
      ARCHIVE_PREFIXES.any? { |prefix| path.start_with?(prefix) }
    end

    # Drop only the folder-name categories Jekyll derives from _posts subdirs.
    # Keep intentional front-matter categories (photos, blog, links, …).
    def clear_folder_categories!(post)
      cats = Array(post.data["categories"]).map(&:to_s)
      post.data["categories"] = cats.reject { |c| FOLDER_CATEGORIES.include?(c) }
    end

    # Markdown images/links: ](media/…) → ](#{prefix}/media/…)
    # HTML src/href: src="media/…" → src="#{prefix}/media/…"
    # Leave absolute http(s) and already-rooted paths alone.
    def rewrite_media_paths!(text, baseurl = "")
      return text if text.nil? || text.empty?

      prefix = baseurl.to_s.chomp("/")
      media_root = "#{prefix}/media/"

      text
        .gsub(%r{\]\(media/}, "](#{media_root}")
        .gsub(%r{(src|href)=(["'])media/}, "\\1=\\2#{media_root}")
    end

    def referenced_media_paths(site)
      paths = {}
      site.posts.docs.each do |post|
        next unless archive_post?(post.relative_path)

        content = post.content.to_s
        content.scan(MEDIA_REF) do
          rel = Regexp.last_match(2).to_s.split("?").first.to_s
          rel = rel.sub(%r{\A/+}, "")
          next if rel.empty?

          paths[rel] = true
        end
      end
      paths
    end

    # Publish only media files actually referenced by archive posts so the
    # GitHub Pages artifact stays smaller (deploy-pages has a hard 10-minute
    # wait timeout that large sites can exceed).
    def register_media_static_files!(site)
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

      Jekyll.logger.info(
        "FixArchiveMedia:",
        "publishing #{registered.size}/#{needed.size} referenced media file(s)"
      )
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
  post.content = Jekyll::FixArchiveMedia.rewrite_media_paths!(post.content, baseurl)
  if post.data["excerpt"] && post.data["excerpt"].respond_to?(:content)
    post.data["excerpt"].content =
      Jekyll::FixArchiveMedia.rewrite_media_paths!(post.data["excerpt"].content, baseurl)
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  Jekyll::FixArchiveMedia.register_media_static_files!(site)
end
