# frozen_string_literal: true

# Tag/category hygiene (issue #140):
#
# 1. Coerce YAML quirks (integer tags like 404 / 2010 break Liquid filters).
# 2. Normalize strings so autopages don't emit duplicate slugs
#    (e.g. "google+" vs "google", "dr. seuss" vs "dr seuss").
# 3. Merge known aliases + singular/plural pairs into one canonical label.
# 4. Expose helpers for the /tags index and prune leftover /tags/:name pages.
#
# Min posts for a public /tags list entry. Chips always link to /tags?tag=
# (issue #209); individual tag archives are not generated.
MIN_TAG_ARCHIVE_POSTS = 2

module Jekyll
  module NormalizeTags
    module_function

    # Explicit synonym map: alias (normalized) → preferred canonical form.
    # Keys and values should already match normalize_tag() output.
    # Prefer the more common English form; singular/plural auto-merge covers
    # the rest when both appear in the corpus.
    ALIASES = {
      # Obvious plural / synonym collapses (canonical = more useful label)
      "gifs" => "gif",
      "comics" => "comic",
      "quotes" => "quote",
      "bikes" => "bike",
      "biking" => "bike",
      "cycling" => "bike",
      "books" => "book",
      "illustrations" => "illustration",
      "infographics" => "infographic",
      "maps" => "map",
      "movies" => "movie",
      "photos" => "photo",
      "posters" => "poster",
      "apps" => "app",
      "fonts" => "font",
      "games" => "game",
      "video games" => "video game",
      "favorite tweets" => "favorite tweet",
      "book covers" => "book cover",
      "images" => "image",
      "interviews" => "interview",
      "lists" => "list",
      "owls" => "owl",
      "cities" => "city",
      "babies" => "baby",
      "tweet" => "twitter",
      "tweets" => "twitter",
      "comic books" => "comic",
      "blackandwhite" => "black and white",
      "black-and-white" => "black and white",
      "the atlantic" => "atlantic",
      "the economist" => "economist",
      # Noise / not useful as taxonomies
      "--" => ""
    }.freeze

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

    def apply_alias(tag)
      ALIASES.fetch(tag, tag)
    end

    def coerce_list!(post, attr)
      value = post.data[attr]
      return if value.nil?

      post.data[attr] = Array(value).flatten.map { |v| normalize_tag(v) }
                                     .map { |v| apply_alias(v) }
                                     .reject(&:empty?)
                                     .uniq
    end

    def coerce!(post)
      coerce_list!(post, "tags")
      coerce_list!(post, "categories")
    end

    def reset_caches!(site)
      site.instance_variable_set(:@tags, nil)
      site.instance_variable_set(:@categories, nil)
    end

    # Build a singular↔plural merge map preferring the form with more posts.
    # Only merges when both forms exist after normalize+alias.
    def singular_plural_map(counts)
      map = {}
      keys = counts.keys
      keys.each do |key|
        next if key.empty?

        candidates = []
        if key.end_with?("ies") && key.length > 4
          candidates << (key[0..-4] + "y")
        elsif key.end_with?("es") && key.length > 3
          candidates << key[0..-3]
          candidates << key[0..-2] # e.g. boxes → boxe (ignored if missing)
        elsif key.end_with?("s") && key.length > 3 && !key.end_with?("ss")
          candidates << key[0..-2]
        end

        candidates.each do |other|
          next unless counts.key?(other)

          # Prefer higher count; ties → shorter label
          a_count = counts[key]
          b_count = counts[other]
          canonical = if a_count > b_count
                        key
                      elsif b_count > a_count
                        other
                      else
                        key.length <= other.length ? key : other
                      end
          map[key] = canonical
          map[other] = canonical
        end
      end
      map
    end

    def merge_related_tags!(site, extra_docs: [])
      counts = Hash.new(0)
      site.posts.docs.each do |post|
        Array(post.data["tags"]).each { |t| counts[t] += 1 }
      end
      extra_docs.each do |doc|
        Array(doc.data["tags"]).each { |t| counts[t] += 1 }
      end

      merge = singular_plural_map(counts)
      return if merge.empty?

      (site.posts.docs + extra_docs).each do |doc|
        tags = Array(doc.data["tags"])
        next if tags.empty?

        doc.data["tags"] = tags.map { |t| merge.fetch(t, t) }.reject(&:empty?).uniq
      end
    end

    def tag_post_count(site, tag)
      list = site.tags[tag.to_s]
      list ? list.size : 0
    end

    def archiveable_tag?(site, tag, min = MIN_TAG_ARCHIVE_POSTS)
      tag_post_count(site, tag) >= min
    end

    # Drop leftover individual tag archives. Tag discovery is /tags?tag= (#209).
    # Runs at :pre_render so it is after PaginationGenerator (:lowest).
    def page_tag_name(page)
      tag = page.data["tag"]
      return tag.to_s unless tag.nil? || tag.to_s.empty?

      # jekyll-paginate-v2 stores the tag on the pagination config, not data.tag
      nested = page.data.dig("pagination", "tag")
      return nested.to_s unless nested.nil? || nested.to_s.empty?

      url = page.url.to_s
      m = url.match(%r{/tags/([^/]+)})
      m ? m[1].to_s : ""
    end

    def tag_index_url?(url)
      url.to_s.sub(/\.html\z/, "").sub(%r{/\z}, "") == "/tags"
    end

    def tag_archive_page?(page)
      return false if tag_index_url?(page.url)
      return true if page.url.to_s.match?(%r{/tags/.+})
      return false unless page.data["autogen"].to_s == "jekyll-paginate-v2"
      return true unless page.data["tag"].to_s.empty?

      nested = page.data.dig("pagination", "tag")
      !(nested.nil? || nested.to_s.empty?)
    end

    def prune_tag_archive_pages!(site)
      site.pages.reject! { |page| tag_archive_page?(page) }
    end
  end
end

Jekyll::Hooks.register :posts, :post_init do |post|
  Jekyll::NormalizeTags.coerce!(post)
end

Jekyll::Hooks.register :site, :post_read do |site|
  site.posts.docs.each { |post| Jekyll::NormalizeTags.coerce!(post) }
  Jekyll::NormalizeTags.reset_caches!(site)
  Jekyll::NormalizeTags.merge_related_tags!(site)
  Jekyll::NormalizeTags.reset_caches!(site)
  site.config["tag_archive_min_posts"] = MIN_TAG_ARCHIVE_POSTS
end

Jekyll::Hooks.register :site, :pre_render do |site|
  Jekyll::NormalizeTags.prune_tag_archive_pages!(site)
end
