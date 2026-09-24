# frozen_string_literal: true

require_relative "helper"
require_relative "../_plugins/site_index"

class TestSiteIndex < Minitest::Test
  S = Jekyll::SiteIndex

  def test_truncate_short_text_unchanged
    assert_equal "hello", S.truncate("hello", 140)
  end

  def test_truncate_cuts_at_word_boundary
    assert_equal "hello world...", S.truncate("hello world foo bar baz", 15)
  end

  def test_truncate_tiny_max_returns_omission
    assert_equal "...", S.truncate("hello world", 3)
  end

  def test_plain_text_strips_code
    assert_equal "hello world", S.plain_text("hello ```code block``` world")
    assert_equal "hello world", S.plain_text("hello `inline` world")
  end

  def test_plain_text_strips_images_but_keeps_link_text
    assert_equal "hello world", S.plain_text("hello ![alt](https://example.com/a.jpg) world")
    assert_equal "hello link world", S.plain_text("hello [link](https://example.com) world")
  end

  def test_plain_text_strips_html_and_ials
    assert_equal "hello world", S.plain_text('hello <b>world</b>')
    assert_equal "hello world", S.plain_text("hello\n{: .caption}\nworld")
  end
end
