# frozen_string_literal: true

require_relative "helper"
require_relative "../_plugins/normalize_tags"

class TestNormalizeTags < Minitest::Test
  N = Jekyll::NormalizeTags

  def test_normalize_tag_symbols_and_punctuation
    assert_equal "google plus", N.normalize_tag("google+")
    assert_equal "dr seuss", N.normalize_tag("Dr. Seuss")
    assert_equal "hello world", N.normalize_tag("  Hello, World!  ")
  end

  def test_normalize_tag_coerces_non_strings
    assert_equal "404", N.normalize_tag(404)
  end

  def test_apply_alias_known_entries
    assert_equal "gif", N.apply_alias("gifs")
    assert_equal "bike", N.apply_alias("cycling")
    assert_equal "twitter", N.apply_alias("tweets")
  end

  def test_apply_alias_unknown_passthrough
    assert_equal "ruby", N.apply_alias("ruby")
  end

  def test_singular_plural_map_prefers_higher_count
    map = N.singular_plural_map({ "cat" => 3, "cats" => 5 })
    assert_equal "cats", map["cat"]
    assert_equal "cats", map["cats"]
  end

  def test_singular_plural_map_tie_prefers_shorter
    map = N.singular_plural_map({ "cat" => 2, "cats" => 2 })
    assert_equal "cat", map["cat"]
    assert_equal "cat", map["cats"]
  end

  def test_singular_plural_map_ies_pair
    map = N.singular_plural_map({ "city" => 1, "cities" => 4 })
    assert_equal "cities", map["city"]
    assert_equal "cities", map["cities"]
  end

  def test_singular_plural_map_no_pair
    assert_empty N.singular_plural_map({ "ruby" => 3 })
  end
end
