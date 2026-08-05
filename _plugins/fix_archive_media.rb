# frozen_string_literal: true

# Historical posts under _posts/v1-archive/ and _posts/v2-archive/ use relative
# media paths like ![](media/12345.jpg). With directory-style permalinks those
# resolve under the post URL (e.g. /2014/10/14/hug/media/…), which is wrong.
#
# Leave media files where they are in the repo (_posts/v2-archive/media/ etc.).
# At build time:
#   1. Rewrite content URLs: media/… → /media/…
#   2. Publish those files as static assets at site-root /media/…
#
# Also clear folder-derived categories so archive posts use the same
# /:year/:month/:day/:title/ shape as current posts (no /v2-archive/ segment).
module Jekyll
  class ArchiveMediaFile < StaticFile
    def initialize(site, base, dir, name, dest_dir)
      super(site, base, dir, name)
      @dest_dir = dest_dir
    end

    def destination(dest)
      File.join(dest, @dest_dir, @name)
    end

    def url
      "/#{File.join(@dest_dir, @name).gsub(%r{/+}, '/')}"
    end

    def relative_path
      File.join(@dest_dir, @name)
    end
  end

  module FixArchiveMedia
    ARCHIVE_PREFIXES = %w[_posts/v1-archive/ _posts/v2-archive/].freeze
    MEDIA_SOURCE_DIRS = %w[_posts/v1-archive/media _posts/v2-archive/media].freeze

    module_function

    def archive_post?(path)
      ARCHIVE_PREFIXES.any? { |prefix| path.start_with?(prefix) }
    end

    def clear_folder_categories!(post)
      post.data["categories"] = []
    end

    # Markdown images/links: ](media/…) → ](/media/…)
    # HTML src/href: src="media/…" → src="/media/…"
    # Leave absolute http(s) and already-rooted /media/ alone.
    def rewrite_media_paths!(text)
      return text if text.nil? || text.empty?

      text
        .gsub(%r{\]\(media/}, "](/media/")
        .gsub(%r{(src|href)=(["'])media/}, "\\1=\\2/media/")
    end

    # Publish every file under the archive media source dirs as StaticFiles
    # rooted at /media/ so rewritten URLs resolve. Source tree is left untouched.
    def register_media_static_files!(site)
      MEDIA_SOURCE_DIRS.each do |src_dir|
        abs = File.join(site.source, src_dir)
        next unless File.directory?(abs)

        Dir.chdir(abs) do
          Dir.glob("**/*", File::FNM_DOTMATCH).each do |rel|
            next unless File.file?(rel)

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
          end
        end
      end
    end
  end
end

Jekyll::Hooks.register :posts, :post_init do |post|
  next unless Jekyll::FixArchiveMedia.archive_post?(post.relative_path)

  Jekyll::FixArchiveMedia.clear_folder_categories!(post)
end

Jekyll::Hooks.register :posts, :pre_render do |post|
  next unless Jekyll::FixArchiveMedia.archive_post?(post.relative_path)

  post.content = Jekyll::FixArchiveMedia.rewrite_media_paths!(post.content)
  if post.data["excerpt"] && post.data["excerpt"].respond_to?(:content)
    post.data["excerpt"].content =
      Jekyll::FixArchiveMedia.rewrite_media_paths!(post.data["excerpt"].content)
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  Jekyll::FixArchiveMedia.register_media_static_files!(site)
end
