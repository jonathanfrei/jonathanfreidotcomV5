# frozen_string_literal: true

require_relative "helper"
require_relative "../_plugins/url_embeds"

class TestUrlEmbeds < Minitest::Test
  E = Jekyll::UrlEmbeds

  def test_youtube_watch
    html = E.embed_for("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    assert_includes html, "youtube-nocookie.com/embed/dQw4w9WgXcQ"
  end

  def test_youtube_short
    html = E.embed_for("https://youtu.be/dQw4w9WgXcQ")
    assert_includes html, "youtube-nocookie.com/embed/dQw4w9WgXcQ"
  end

  def test_vimeo
    html = E.embed_for("https://vimeo.com/123456789")
    assert_includes html, "player.vimeo.com/video/123456789"
  end

  def test_spotify_track_height
    html = E.embed_for("https://open.spotify.com/track/abc123XYZ")
    assert_includes html, "open.spotify.com/embed/track/abc123XYZ"
    assert_includes html, 'height="152"'
  end

  def test_spotify_playlist_height
    html = E.embed_for("https://open.spotify.com/playlist/abc123XYZ")
    assert_includes html, 'height="352"'
  end

  def test_imgur_single_page_prefers_direct_image
    html = E.embed_for("https://imgur.com/abc12")
    assert_includes html, "https://i.imgur.com/abc12.jpg"
    assert_includes html, "<img"
  end

  def test_imgur_direct_video
    html = E.embed_for("https://i.imgur.com/abc12.mp4")
    assert_includes html, "<video"
    assert_includes html, "https://i.imgur.com/abc12.mp4"
  end

  def test_flickr_photo
    html = E.embed_for("https://www.flickr.com/photos/someuser/12345678901")
    assert_includes html, 'data-flickr-embed="true"'
    assert_includes html, "https://www.flickr.com/photos/someuser/12345678901/"
  end

  def test_unknown_url_returns_nil
    assert_nil E.embed_for("https://example.com/some/article")
  end
end
