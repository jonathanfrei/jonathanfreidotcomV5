# frozen_string_literal: true

# Converts standalone media URLs in Markdown into responsive embeds at build time.
# A URL on its own line (blank lines around it) is replaced with platform-specific HTML.
#
# Supported (common URL shapes):
#   YouTube  – youtube.com/watch, youtu.be, youtube.com/shorts, youtube.com/embed
#   Vimeo    – vimeo.com/{id}
#   X/Twitter – x.com|twitter.com/{user}/status/{id}
#   Instagram – instagram.com/p|reel|reels/{code}
#   TikTok   – tiktok.com/@user/video/{id}
#   Spotify  – open.spotify.com/{type}/{id}
#   CodePen  – codepen.io/{user}/pen/{id}
#   Imgur    – i.imgur.com/{id}.{ext}, imgur.com/{id}, imgur.com/a/{id}, imgur.com/gallery/{id}
#   Flickr   – flickr.com/photos/{user}/{id}, flic.kr/p/{shortcode}
#
# HTML is emitted with markdown="0" and no leading indentation so Kramdown's
# parse_block_html does not treat embed markup as a fenced/indented code block
# (issues #156, #157).
#
# Usage in a post/page:
#
#   Some text.
#
#   https://www.youtube.com/watch?v=dQw4w9WgXcQ
#
#   More text.

module Jekyll
  module UrlEmbeds
    # Match a whole line that is only a http(s) URL (optional trailing slash/query).
    STANDALONE_URL = %r{
      (?<=\A|\n)\s*
      (https?://[^\s<>\[\]]+)
      \s*(?=\n|\z)
    }x.freeze

    # Imgur image hashes are 5–8 alnum chars; SEO gallery slugs end with that hash.
    IMGUR_HASH = /[A-Za-z0-9]{5,8}/.freeze

    module_function

    def process(content)
      return content if content.nil? || content.empty?

      content.gsub(STANDALONE_URL) do
        url = Regexp.last_match(1).strip
        embed_for(url) || Regexp.last_match(0)
      end
    end

    def embed_for(url)
      case url
      when %r{(?:youtube\.com/(?:watch\?v=|embed/|shorts/)|youtu\.be/)([A-Za-z0-9_-]{6,})}
        youtube($1)
      when %r{vimeo\.com/(?:video/)?(\d+)}
        vimeo($1)
      when %r{(?:twitter\.com|x\.com)/[^/]+/status(?:es)?/(\d+)}
        twitter(url, $1)
      when %r{instagram\.com/(?:p|reel|reels)/([A-Za-z0-9_-]+)}
        instagram(url, $1)
      when %r{tiktok\.com/@[^/]+/video/(\d+)}
        tiktok(url, $1)
      when %r{open\.spotify\.com/(track|album|playlist|episode|show)/([A-Za-z0-9]+)}
        spotify($1, $2)
      when %r{codepen\.io/([^/]+)/pen/([A-Za-z0-9]+)}
        codepen($1, $2)
      # Direct CDN video: i.imgur.com/{id}.gifv|.mp4|.webm
      when %r{i\.imgur\.com/(#{IMGUR_HASH.source})\.(?:gifv|mp4|webm)}i
        imgur_video($1)
      # Direct CDN image: i.imgur.com/{id}.{ext}
      when %r{i\.imgur\.com/([A-Za-z0-9]+)(\.[a-zA-Z0-9]+)?}i
        imgur_image(url, $1, $2)
      # Album: imgur.com/a/{id} (SEO slugs may include hyphens)
      when %r{imgur\.com/a/([A-Za-z0-9-]+)}i
        imgur_album($1)
      # Gallery: imgur.com/gallery/{id-or-seo-slug}
      when %r{imgur\.com/gallery/([A-Za-z0-9-]+)}i
        imgur_gallery($1)
      # Single post page: imgur.com/{id} (exclude /user, /t/, etc.)
      when %r{imgur\.com/(?!a/|gallery/|user/|t/|r/|signin)([A-Za-z0-9]+)(?:\.[a-zA-Z0-9]+)?(?:[/?#]|$)}i
        imgur_single($1)
      # Flickr short links: flic.kr/p/{code}
      when %r{flic\.kr/p/([A-Za-z0-9]+)}i
        flickr_short($1)
      # Flickr photo page: flickr.com/photos/{user}/{id}
      when %r{(?:www\.)?flickr\.com/photos/([^/]+)/(\d+)}i
        flickr_photo($1, $2, url)
      # Flickr album/set: flickr.com/photos/{user}/albums|sets/{id}
      when %r{(?:www\.)?flickr\.com/photos/([^/]+)/(?:albums|sets)/(\d+)}i
        flickr_album($1, $2)
      else
        nil
      end
    end

    def youtube(id)
      wrap_video(
        %(<iframe src="https://www.youtube-nocookie.com/embed/#{id}" title="YouTube video" ) +
          %(frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" ) +
          %(allowfullscreen loading="lazy"></iframe>)
      )
    end

    def vimeo(id)
      wrap_video(
        %(<iframe src="https://player.vimeo.com/video/#{id}" title="Vimeo video" ) +
          %(frameborder="0" allow="autoplay; fullscreen; picture-in-picture" allowfullscreen loading="lazy"></iframe>)
      )
    end

    def twitter(url, id)
      <<~HTML.gsub(/^[ \t]+/, "")

        <div class="embed embed-twitter" data-embed="twitter" markdown="0">
        <blockquote class="twitter-tweet" data-dnt="true">
        <a href="https://twitter.com/i/status/#{id}">View post on X</a>
        </blockquote>
        </div>

      HTML
    end

    def instagram(url, code)
      canonical = url.sub(%r{/reels/}, "/reel/").split("?").first
      canonical += "/" unless canonical.end_with?("/")
      <<~HTML.gsub(/^[ \t]+/, "")

        <div class="embed embed-instagram" data-embed="instagram" markdown="0">
        <blockquote class="instagram-media" data-instgrm-permalink="#{canonical}" data-instgrm-version="14" style="width:100%; max-width:540px; margin:0 auto;">
        <a href="#{canonical}">View post on Instagram</a>
        </blockquote>
        </div>

      HTML
    end

    def tiktok(url, id)
      <<~HTML.gsub(/^[ \t]+/, "")

        <div class="embed embed-tiktok" data-embed="tiktok" markdown="0">
        <blockquote class="tiktok-embed" cite="#{url}" data-video-id="#{id}" style="max-width:605px; min-width:325px; margin:0 auto;">
        <a href="#{url}">View on TikTok</a>
        </blockquote>
        </div>

      HTML
    end

    def spotify(type, id)
      height = %w[track episode].include?(type) ? 152 : 352
      <<~HTML.gsub(/^[ \t]+/, "")

        <div class="embed embed-spotify" data-embed="spotify" markdown="0">
        <iframe style="border-radius:12px" src="https://open.spotify.com/embed/#{type}/#{id}" width="100%" height="#{height}" frameborder="0" allowfullscreen allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" loading="lazy"></iframe>
        </div>

      HTML
    end

    def codepen(user, id)
      wrap_video(
        %(<iframe src="https://codepen.io/#{user}/embed/#{id}?default-tab=result" title="CodePen" ) +
          %(loading="lazy" allowfullscreen></iframe>),
        ratio: "56.25%"
      )
    end

    # Direct image CDN links → responsive <img>
    # (hotlink CDN proxy via wsrv.nl applied later by optimize_content_images)
    def imgur_image(url, id, ext)
      src = url.split("?").first
      # Prefer https
      src = src.sub(%r{\Ahttp://}, "https://")
      ext = ext.to_s
      ext = ".jpg" if ext.empty?
      # Normalize bare id pages that matched as i.imgur.com/{id}
      src = "https://i.imgur.com/#{id}#{ext}" unless src.include?("i.imgur.com")
      <<~HTML.gsub(/^[ \t]+/, "")

        <figure class="embed embed-imgur" data-embed="imgur" markdown="0">
        <img src="#{src}" alt="Imgur image" loading="lazy" decoding="async" />
        </figure>

      HTML
    end

    # Hosted gifv/mp4 → native video (no Imgur widget required)
    def imgur_video(id)
      <<~HTML.gsub(/^[ \t]+/, "")

        <div class="embed embed-imgur embed-imgur-video" data-embed="imgur" markdown="0">
        <video controls playsinline loop muted preload="metadata" poster="https://i.imgur.com/#{id}.jpg">
        <source src="https://i.imgur.com/#{id}.mp4" type="video/mp4">
        </video>
        </div>

      HTML
    end

    def imgur_album(slug)
      id = imgur_resolve_id(slug)
      imgur_blockquote("a/#{id}", "https://imgur.com/a/#{slug}")
    end

    def imgur_gallery(slug)
      id = imgur_resolve_id(slug)
      # SEO slugs (hyphenated) are almost always a single image/video; embed
      # with the trailing hash so the official widget loads the right media.
      if slug.include?("-")
        imgur_blockquote(id, "https://imgur.com/gallery/#{slug}")
      else
        imgur_blockquote(id, "https://imgur.com/gallery/#{id}")
      end
    end

    def imgur_single(id)
      # Prefer direct image when possible (faster + CDN-proxyable) over blockquote widget
      imgur_image("https://i.imgur.com/#{id}.jpg", id, ".jpg")
    end

    # Extract the real Imgur hash from SEO slugs like "warning-canadian-porn-dvYAhGa".
    def imgur_resolve_id(slug)
      return slug if slug.match?(/\A#{IMGUR_HASH.source}\z/)

      trailing = slug[/-((?:#{IMGUR_HASH.source}))\z/, 1]
      trailing || slug
    end

    def imgur_blockquote(data_id, href)
      <<~HTML.gsub(/^[ \t]+/, "")

        <div class="embed embed-imgur" data-embed="imgur" markdown="0">
        <blockquote class="imgur-embed-pub" lang="en" data-id="#{data_id}">
        <a href="#{href}">View on Imgur</a>
        </blockquote>
        </div>

      HTML
    end

    # Flickr photo page → official embedr widget (#122)
    # embedr.flickr.com upgrades data-flickr-embed anchors when its script loads.
    def flickr_photo(user, photo_id, _url)
      canonical = "https://www.flickr.com/photos/#{user}/#{photo_id}/"
      flickr_embed_link(canonical, "View photo on Flickr")
    end

    def flickr_short(code)
      flickr_embed_link("https://flic.kr/p/#{code}", "View photo on Flickr")
    end

    def flickr_album(user, album_id)
      flickr_embed_link(
        "https://www.flickr.com/photos/#{user}/albums/#{album_id}",
        "View album on Flickr"
      )
    end

    def flickr_embed_link(href, label)
      <<~HTML.gsub(/^[ \t]+/, "")

        <div class="embed embed-flickr" data-embed="flickr" markdown="0">
        <a data-flickr-embed="true" data-header="false" data-footer="true" href="#{href}" title="#{label}">#{label}</a>
        </div>

      HTML
    end

    def wrap_video(iframe_html, ratio: "56.25%")
      # No indentation inside the shell: parse_block_html + indented lines → CodeRay (#156).
      <<~HTML.gsub(/^[ \t]+/, "")

        <div class="embed embed-video" data-embed="video" style="--embed-ratio: #{ratio};" markdown="0">
        <div class="embed-video__inner">
        #{iframe_html}
        </div>
        </div>

      HTML
    end
  end
end

Jekyll::Hooks.register [:posts, :pages, :documents], :pre_render do |doc|
  next unless doc.respond_to?(:content) && doc.content.is_a?(String)
  next if doc.data["url_embeds"] == false

  doc.content = Jekyll::UrlEmbeds.process(doc.content)
end
