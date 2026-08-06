# frozen_string_literal: true

# YAML unquoted numbers become Integers (e.g. tags: [404] or tags: [2010]).
# Integer tags break Liquid | slugify (no gsub) and | sort on site.tags
# (comparison of Array with Array failed).
#
# Also normalize tag strings so autopages don't emit two pages that slugify
# to the same path (e.g. "google+" vs "google", "dr. seuss" vs "dr seuss").
module Jekyll
  module NormalizeTags
    module_function

    def normalize_tag(value)
      s = value.to_s.strip.downcase
      # Preserve meaning for common symbols before stripping
      s = s.gsub("+", " plus ")
      s = s.gsub("&", " and ")
      # Drop punctuation that Jekyll slugify would remove; keep word separators
      s = s.gsub(/[^a-z0-9\s-]+/, " ")
      s = s.gsub(/\s+/, " ").strip
      s
    end

    def coerce!(post)
      %w[tags categories].each do |attr|
        value = post.data[attr]
        next if value.nil?

        post.data[attr] = Array(value).flatten.map { |v| normalize_tag(v) }.reject(&:empty?).uniq
      end
    end

    def reset_caches!(site)
      site.instance_variable_set(:@tags, nil)
      site.instance_variable_set(:@categories, nil)
    end
  end
end

Jekyll::Hooks.register :posts, :post_init do |post|
  Jekyll::NormalizeTags.coerce!(post)
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.posts.docs.each { |post| Jekyll::NormalizeTags.coerce!(post) }
  Jekyll::NormalizeTags.reset_caches!(site)
end
