# frozen_string_literal: true

require_relative "helper"
require_relative "../_plugins/stream_pages"

class TestStreamPages < Minitest::Test
  P = Jekyll::StreamPagination

  def test_total_pages_exact_and_partial
    assert_equal 2, P.total_pages(200, 100)
    assert_equal 3, P.total_pages(201, 100)
    assert_equal 1, P.total_pages(0, 100)
  end

  def test_path_for_page_one_is_base
    assert_equal "/blog", P.path_for("/blog", 1)
    assert_equal "/blog", P.path_for("/blog", 0)
    assert_equal "/blog/page/2/", P.path_for("/blog", 2)
  end

  def test_trail_windows_around_current
    trail = P.trail(5, 10, "/blog")
    assert_equal [3, 4, 5, 6, 7], trail.map { |t| t["num"] }
    assert_equal "/blog/page/5/", trail.find { |t| t["num"] == 5 }["path"]
  end

  def test_trail_clamps_at_edges
    assert_equal [1, 2, 3], P.trail(1, 10, "/blog").map { |t| t["num"] }
    assert_equal [8, 9, 10], P.trail(10, 10, "/blog").map { |t| t["num"] }
  end

  def test_paginator_first_page
    p = P.paginator(1, 250, 100, "/blog")
    assert_equal 3, p["total_pages"]
    assert_nil p["previous_page"]
    assert_nil p["previous_page_path"]
    assert_equal 2, p["next_page"]
    assert_equal "/blog/page/2/", p["next_page_path"]
    assert_equal "/blog", p["first_page_path"]
  end

  def test_paginator_last_page
    p = P.paginator(3, 250, 100, "/blog")
    assert_equal 2, p["previous_page"]
    assert_equal "/blog/page/2/", p["previous_page_path"]
    assert_nil p["next_page"]
    assert_nil p["next_page_path"]
  end
end
