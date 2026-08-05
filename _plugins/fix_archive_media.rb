# frozen_string_literal: true

# Historical posts under _posts/v1-archive/ and _posts/v2-archive/ use relative
# media paths like ![](media/12345.jpg). With directory-style permalinks those
# resolve under the post URL (e.g. /v2-archive/2014/10/14/hug/media/…),
# which is wrong. Point them at site-root /media/… instead.
#
# Also clear folder-derived categories so archive posts use the same
# /:year/:month/:day/:title/ shape as current posts (no /v2-archive/ segment).
module Jekyll
  module FixArchiveMedia
    ARCHIVE_PREFIXES = %w[_posts/v1-archive/ _posts/v2-archive/].freeze

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
