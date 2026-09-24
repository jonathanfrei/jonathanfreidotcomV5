# frozen_string_literal: true

require_relative "helper"
require_relative "../_plugins/books"

class TestBooks < Minitest::Test
  B = Jekyll::Books
  FakeDoc = Struct.new(:relative_path, :data, :collection)

  def test_parse_segment_with_suffix
    assert_equal({ int: 2, suffix: "a", slug: "foo" }, B.parse_segment("002a-foo"))
  end

  def test_parse_segment_plain
    assert_equal({ int: 1, suffix: "", slug: "book" }, B.parse_segment("001-book"))
  end

  def test_parse_segment_without_prefix_sorts_last
    parsed = B.parse_segment("intro")
    assert_equal 1_000_000, parsed[:int]
    assert_equal "intro", parsed[:slug]
  end

  def test_permalink_for_book_home
    doc = FakeDoc.new("_books/my-book/001-book.md", {}, nil)
    assert_equal "/books/my-book/book", B.permalink_for(doc)
  end

  def test_permalink_for_nested_section
    doc = FakeDoc.new("_books/my-book/002-chapter/001-section.md", {}, nil)
    assert_equal "/books/my-book/chapter/section", B.permalink_for(doc)
  end

  def test_permalink_for_explicit_slug
    doc = FakeDoc.new("_books/my-book/002-chapter/001-section.md", { "slug" => "custom" }, nil)
    assert_equal "/books/my-book/chapter/section/custom", B.permalink_for(doc)
  end
end
