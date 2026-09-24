# frozen_string_literal: true

require_relative "helper"
require_relative "../_plugins/html_util"
require_relative "../_plugins/site_index"
require_relative "../_plugins/post_metadata"
require_relative "../_plugins/link_posts"
require_relative "../_plugins/optimize_content_images"

class TestHtmlUtil < Minitest::Test
  H = Jekyll::HtmlUtil

  def test_parse_attrs_double_single_bare_boolean
    attrs = H.parse_attrs('src="a.jpg" alt=\'pic\' width=300 loading')
    assert_equal "a.jpg", attrs["src"]
    assert_equal "pic", attrs["alt"]
    assert_equal "300", attrs["width"]
    assert_equal "", attrs["loading"]
  end

  def test_parse_attrs_keys_downcased
    attrs = H.parse_attrs('SRC="a.jpg" ALT="x"')
    assert_equal "a.jpg", attrs["src"]
    assert_equal "x", attrs["alt"]
  end

  def test_parse_attrs_empty_and_trailing_slash_noise
    attrs = H.parse_attrs('src="" alt')
    assert_equal "", attrs["src"]
    assert_equal "", attrs["alt"]
  end

  def test_parse_attrs_value_with_spaces_and_entities
    attrs = H.parse_attrs('title="a & b" data-x=\'1 2\'')
    assert_equal "a & b", attrs["title"]
    assert_equal "1 2", attrs["data-x"]
  end

  def test_serialize_attrs_ordered_first_then_remainder
    attrs = { "alt" => "x", "src" => "a.jpg", "loading" => "lazy" }
    assert_equal 'src="a.jpg" alt="x" loading="lazy"',
                 H.serialize_attrs(attrs, %w[src alt])
  end

  def test_serialize_attrs_default_order_preserves_insertion
    attrs = { "b" => "2", "a" => "1" }
    assert_equal 'b="2" a="1"', H.serialize_attrs(attrs)
  end

  def test_serialize_attrs_escapes_amp_and_quote
    assert_equal 'title="a &amp; b &quot;q&quot;"',
                 H.serialize_attrs({ "title" => 'a & b "q"' })
  end

  def test_serialize_attrs_boolean_and_empty_bare
    assert_equal "loading", H.serialize_attrs({ "loading" => "" })
    assert_equal "loading", H.serialize_attrs({ "loading" => true })
    assert_equal 'alt=""', H.serialize_attrs({ "alt" => nil })
  end

  def test_escape_attr
    assert_equal "a &amp; b &quot;q&quot;", H.escape_attr('a & b "q"')
  end

  def test_format_attr
    assert_equal "loading", H.format_attr("loading", "")
    assert_equal "loading", H.format_attr("loading", true)
    assert_equal 'src="a.jpg"', H.format_attr("src", "a.jpg")
  end

  def test_unescape_markdown_dest
    assert_equal "file_(1957).jpg", H.unescape_markdown_dest('file_\\(1957\\).jpg')
    assert_equal "a\\b", H.unescape_markdown_dest('a\\\\b')
    assert_equal "a\\nb", H.unescape_markdown_dest('a\\nb')
    assert_equal "", H.unescape_markdown_dest(nil)
  end

  def test_strip_markdown_word_count_flavor_keeps_spacing_and_ials
    # word_count flavor: no whitespace collapse, no IAL strip
    assert_equal "a  b", H.strip_markdown_text("a  b")
    assert_equal "{: .caption}", H.strip_markdown_text("{: .caption}").strip
    assert_equal "hello link world",
                 H.strip_markdown_text("hello [link](https://example.com) world").split.join(" ")
  end

  def test_strip_markdown_plain_text_flavor_collapses_and_strips_ials
    out = H.strip_markdown_text("hello\n{: .caption}\nworld",
                                collapse_whitespace: true, strip_ials: true)
    assert_equal "hello world", out
    out2 = H.strip_markdown_text("hello  \n  world",
                                 collapse_whitespace: true, strip_ials: true)
    assert_equal "hello world", out2
  end

  def test_plain_text_wiring_parity
    inputs = [
      "hello ```code block``` world",
      "hello `inline` world",
      "hello ![alt](https://example.com/a.jpg) world",
      "hello [link](https://example.com) world",
      "hello <b>world</b>",
      "hello\n{: .caption}\nworld",
      "# Title\n\nSome *emph* text with [a link](https://example.com/x).",
      "{:.figure-wide}\n\n![alt](https://example.com/a.jpg)"
    ]
    inputs.each do |input|
      assert_equal H.strip_markdown_text(input, collapse_whitespace: true, strip_ials: true),
                   Jekyll::SiteIndex.plain_text(input), "plain_text parity: #{input.inspect}"
    end
  end

  def test_word_count_wiring_parity
    assert_equal 3, Jekyll::PostMetadata.word_count("hello [link](https://example.com) world")
    assert_equal 2, Jekyll::PostMetadata.word_count("hello ```code block``` world")
    assert_equal 0, Jekyll::PostMetadata.word_count("")
    # IALs count as tokens in word_count flavor (no IAL strip), but not in plain_text
    wc_text = H.strip_markdown_text("hello\n{: .caption}\nworld")
    assert_equal wc_text.split(/\s+/).reject(&:empty?).size,
                 Jekyll::PostMetadata.word_count("hello\n{: .caption}\nworld")
    assert_includes wc_text, "{:"
  end

  def test_unescape_wiring_parity
    assert_equal H.unescape_markdown_dest('file_\\(1957\\).jpg'),
                 Jekyll::SiteIndex.unescape_markdown_dest('file_\\(1957\\).jpg')
    assert_equal H.unescape_markdown_dest('file_\\(1957\\).jpg'),
                 Jekyll::OptimizeContentImages.unescape_markdown_dest('file_\\(1957\\).jpg')
  end

  def test_optimizer_wrappers_delegate
    sample = 'src="a.jpg" alt="x" loading'
    assert_equal H.parse_attrs(sample), Jekyll::OptimizeContentImages.parse_attrs(sample)
    attrs = { "src" => "a.jpg", "alt" => "x" }
    assert_equal H.serialize_attrs(attrs, %w[src]), Jekyll::OptimizeContentImages.serialize_attrs(attrs, %w[src])
    assert_equal H.escape_attr('a&"'), Jekyll::OptimizeContentImages.escape_attr('a&"')
  end

  def test_link_posts_attribute_contract
    l = Jekyll::LinkPosts
    assert_equal "og:title", l.attribute('<meta property="og:title" content="Hi">', "property")
    assert_equal "Hi", l.attribute("<meta property='og:title' content='Hi'>", "content")
    assert_equal "Hi", l.attribute('<meta content=Hi>', "content")
    assert_equal "", l.attribute('<meta content="">', "content")
    assert_nil l.attribute('<meta property="og:title">', "content")
    assert_nil l.attribute('<meta>', "content")
    assert_equal "Hi", l.attribute('<META CONTENT="Hi">', "content")
  end

  def test_own_media_roots_folded_in
    o = Jekyll::OptimizeContentImages
    # static_html root paths count even without an image extension
    assert o.own_media?("/editorial/foo.jpg")
    assert o.own_media?("/editorial/foo")
    assert o.own_media?("editorial/foo.jpg")
    assert_equal false, o.own_media?("/about")
    assert_equal false, o.own_media?(nil)
    assert_equal false, o.own_media?("data:image/png;base64,xx")
    # archive + own-media behavior preserved
    assert o.own_media?("https://media.jonathanfrei.com/v2-archive/media/a.jpg")
    # custom roots from site config
    site = OpenStruct.new(config: { "static_html" => { "roots" => ["project"] } })
    assert o.own_media?("/project/app.png", site)
  end
end
