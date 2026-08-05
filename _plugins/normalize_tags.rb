# frozen_string_literal: true

# YAML unquoted numbers become Integers (e.g. tags: [404] or tags: [2010]).
# Integer tags break Liquid | slugify (no gsub) and | sort on site.tags
# (comparison of Array with Array failed).
module Jekyll
  module NormalizeTags
    module_function

    def coerce!(post)
      %w[tags categories].each do |attr|
        value = post.data[attr]
        next if value.nil?

        post.data[attr] = Array(value).flatten.map(&:to_s)
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

# Ensure caches are rebuilt after all posts are loaded (covers any path
# that set tags after post_init).
Jekyll::Hooks.register :site, :post_read do |site|
  site.posts.docs.each { |post| Jekyll::NormalizeTags.coerce!(post) }
  Jekyll::NormalizeTags.reset_caches!(site)
end
