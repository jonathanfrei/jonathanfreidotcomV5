# frozen_string_literal: true

# YAML unquoted numbers become Integers (e.g. tags: [404] or tags: [2010]).
# Integer tags break Liquid | slugify (no gsub) and | sort on site.tags
# (comparison of Array with Array failed). Coerce early so archives and
# templates always see String keys/values.
Jekyll::Hooks.register :posts, :post_init do |post|
  %w[tags categories].each do |attr|
    value = post.data[attr]
    next if value.nil?

    post.data[attr] = Array(value).flatten.map(&:to_s)
  end
end
