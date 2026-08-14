# frozen_string_literal: true

# One-pass derived indexes for search, tags, categories, and archives (#195).
#
# Templates used to walk site.posts / site.tags repeatedly (search.json,
# /tags, /categories, /sitemap, month archive list). That work now happens
# once here; Liquid just dumps the precomputed arrays.
#
# search.json stays a thin payload: kind, title, url, date, short excerpt, tags.
# No description, last_modified, reading_time, or full body.
#
# Config (_config.yml):
#   site_index:
#     excerpt_chars: 140
module Jekyll
  module SiteIndex
    module_function

    DEFAULTS = {
      "excerpt_chars" => 140
    }.freeze

    def build!(site)
      cfg = DEFAULTS.merge(site.config["site_index"] || {})
      excerpt_chars = cfg["excerpt_chars"].to_i
      excerpt_chars = DEFAULTS["excerpt_chars"] if excerpt_chars <= 0
      min_tags = site.config["tag_archive_min_posts"].to_i
      min_tags = 2 if min_tags <= 0

      docs = site.posts.docs.sort_by(&:date).reverse

      site.data["search_index"] = docs.map { |post| search_entry(site, post, excerpt_chars) }
      site.data["tag_counts"] = count_map(site.tags)
      site.data["category_counts"] = count_map(site.categories)
      site.data["archive_tags"] = taxonomy_list(site.tags, min: min_tags)
      site.data["archive_categories"] = taxonomy_list(site.categories, min: 1)
      site.data["archive_months"] = month_list(docs)
      site.data["posts_by_year"] = year_list(docs)

      Jekyll.logger.info "SiteIndex:",
                         "indexed #{docs.size} posts, " \
                         "#{site.data['archive_tags'].size} archive tags, " \
                         "#{site.data['archive_months'].size} months"
    end

    def search_entry(site, post, excerpt_chars)
      {
        "kind" => kind(post),
        "title" => post.data["title"].to_s,
        "url" => relative_url(site, post.url),
        "date" => format_iso_date(post.date),
        "excerpt" => blurb(post, excerpt_chars),
        "tags" => Array(post.data["tags"]).map(&:to_s)
      }
    end

    def kind(post)
      if defined?(Jekyll::LinkPosts) && Jekyll::LinkPosts.link_post?(post)
        "link"
      elsif post.data["layout"].to_s == "link"
        "link"
      else
        "post"
      end
    end

    def blurb(post, max)
      candidates = []
      excerpt = post.data["excerpt"]
      candidates << excerpt if excerpt.is_a?(String) && !excerpt.strip.empty?
      desc = post.data["description"]
      candidates << desc if desc.is_a?(String) && !desc.strip.empty?
      candidates << post.content.to_s

      text = ""
      candidates.each do |candidate|
        text = plain_text(candidate)
        break unless text.empty?
      end
      truncate(text, max)
    end

    def plain_text(input)
      text = input.to_s.dup
      text.gsub!(/```.*?```/m, " ")
      text.gsub!(/`[^`]*`/, " ")
      text.gsub!(/!\[[^\]]*\]\([^)]*\)/, " ")
      text.gsub!(/\[([^\]]*)\]\([^)]*\)/, '\1')
      text.gsub!(/<[^>]+>/, " ")
      text.gsub!(/[#>*_\-|]+/, " ")
      text.gsub!(/\s+/, " ")
      text.strip
    end

    def truncate(text, max)
      return text if text.length <= max

      omission = "..."
      keep = max - omission.length
      return omission if keep <= 0

      cut = text[0, keep]
      if (space = cut.rindex(" ")) && space > (keep * 0.6)
        cut = cut[0, space]
      end
      "#{cut.rstrip}#{omission}"
    end

    def relative_url(site, path)
      base = site.config["baseurl"].to_s
      base = "" if base == "/"
      base = base.sub(%r{/\z}, "")
      href = path.to_s
      href = "/#{href}" unless href.start_with?("/")
      "#{base}#{href}"
    end

    def format_iso_date(value)
      return "" unless value.respond_to?(:strftime)

      value.strftime("%Y-%m-%d")
    end

    def count_map(hash)
      hash.each_with_object({}) do |(name, docs), acc|
        acc[name.to_s] = docs.size
      end
    end

    def taxonomy_list(hash, min: 1)
      hash.filter_map do |name, docs|
        count = docs.size
        next if count < min

        {
          "name" => name.to_s,
          "count" => count,
          "slug" => Utils.slugify(name.to_s)
        }
      end.sort_by { |row| [-row["count"], row["name"]] }
    end

    def month_list(docs)
      groups = Hash.new { |h, k| h[k] = [] }
      docs.each do |post|
        next unless post.date

        groups[post.date.strftime("%Y-%m")] << post
      end

      groups.keys.sort.reverse.map do |key|
        year, month = key.split("-", 2)
        sample = groups[key].first.date
        {
          "year" => year,
          "month" => month,
          "label" => sample.strftime("%B %Y"),
          "count" => groups[key].size
        }
      end
    end

    def year_list(docs)
      groups = Hash.new { |h, k| h[k] = [] }
      docs.each do |post|
        next unless post.date

        groups[post.date.strftime("%Y")] << {
          "title" => post.data["title"].to_s,
          "url" => post.url.to_s,
          "date_label" => "#{post.date.strftime('%b')} #{post.date.day}"
        }
      end

      groups.keys.sort.reverse.map do |year|
        { "name" => year, "items" => groups[year] }
      end
    end
  end

  class SiteIndexGenerator < Generator
    safe true
    priority :low

    def generate(site)
      SiteIndex.build!(site)
    end
  end
end
