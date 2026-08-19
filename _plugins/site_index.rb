# frozen_string_literal: true

# One-pass derived indexes for search, tags, categories, and archives (#195).
#
# Templates used to walk site.posts / site.tags repeatedly (search.json,
# /tags, /categories, /sitemap, month archive list). That work now happens
# once here; Liquid just dumps the precomputed arrays.
#
# search.json stays a thin payload: kind, title, url, date (ISO), date_label
# (long, e.g. "August 17, 2026"), short excerpt, tags, categories, and the
# first non-GIF content image (src + alt) when one exists (#219).
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
      entry = {
        "kind" => kind(post),
        "title" => post.data["title"].to_s,
        "url" => relative_url(site, post.url),
        "date" => format_iso_date(post.date),
        "date_label" => format_long_date(post.date),
        "excerpt" => blurb(post, excerpt_chars),
        "tags" => Array(post.data["tags"]).map(&:to_s),
        "categories" => Array(post.data["categories"]).map(&:to_s)
      }
      img = first_image(site, post)
      entry["img"] = img if img
      entry
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
      # Kramdown IALs / ALDs ({: .figure-wide}, {: .caption}, {::comment}).
      # Strip before hyphen collapsing or `{:.figure-wide}` becomes
      # `{: .figure wide}` in search.json excerpts.
      text.gsub!(/\{::?[^}]*\}/, " ")
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

    # Portable long date. Avoid "%-d" — MSVC strftime on Windows rejects it.
    def format_long_date(value)
      return "" unless value.respond_to?(:year)

      "#{value.strftime("%B")} #{value.day}, #{value.year}"
    end

    # First usable <img> / markdown image in the post body. GIFs stay off
    # list views (same policy as list_excerpt). Archive media/ paths are
    # resolved the same way FixArchiveMedia rewrites them at render time.
    MD_IMG = %r{!\[([^\]]*)\]\(\s*(?:<([^>]+)>|((?:\\[()]|[^)\s])+))}.freeze
    HTML_IMG = %r{<img\b[^>]*>}i.freeze

    def first_image(site, post)
      each_source_image(post.content.to_s) do |src, alt|
        resolved = normalize_img_src(site, post, src)
        next unless usable_img_src?(resolved)

        return { "src" => resolved, "alt" => alt.to_s }
      end

      fallback = post.data["image"].to_s.strip
      if !fallback.empty?
        resolved = normalize_img_src(site, post, fallback)
        if usable_img_src?(resolved)
          alt = post.data["image_alt"].to_s
          return { "src" => resolved, "alt" => alt }
        end
      end

      nil
    end

    def each_source_image(content)
      found = []
      content.to_s.scan(MD_IMG) do
        src = (Regexp.last_match(2) || Regexp.last_match(3)).to_s
        found << [Regexp.last_match.begin(0), src, Regexp.last_match(1).to_s]
      end
      content.to_s.scan(HTML_IMG) do
        tag = Regexp.last_match[0]
        src = tag[/\bsrc\s*=\s*["']([^"']+)["']/i, 1]
        next if src.nil?

        alt = tag[/\balt\s*=\s*["']([^"']*)["']/i, 1].to_s
        found << [Regexp.last_match.begin(0), src, alt]
      end
      found.sort_by(&:first).each { |_, src, alt| yield src, alt }
    end

    def normalize_img_src(site, post, src)
      value = unescape_markdown_dest(src.to_s).strip
      value = value.sub(/\A["']/, "").sub(/["']\z/, "")
      return "" if value.empty?

      if value.match?(%r{\Amedia/}i)
        return resolve_archive_media_src(site, post, value)
      end
      return value if value.match?(%r{\Ahttps?://}i)
      return relative_url(site, value) if value.start_with?("/")

      ""
    end

    def resolve_archive_media_src(site, post, src)
      rel = src.sub(%r{\Amedia/}i, "")
      path = post.respond_to?(:relative_path) ? post.relative_path.to_s : ""
      if defined?(Jekyll::FixArchiveMedia) &&
         Jekyll::FixArchiveMedia.archive_post?(path)
        slug = Jekyll::FixArchiveMedia.archive_slug_for_post(path)
        baseurl = site.config["baseurl"] || ""
        mode_name = Jekyll::FixArchiveMedia.mode(site)
        return Jekyll::FixArchiveMedia.resolve_media_url(
          site, rel, baseurl, mode_name, archive_slug: slug
        ).to_s
      end

      relative_url(site, "/media/#{rel.sub(%r{\A/+}, "")}")
    end

    def unescape_markdown_dest(src)
      src.to_s.gsub(/\\([()\\])/, '\1')
    end

    def usable_img_src?(src)
      return false if src.nil? || src.empty?
      return false if gif_src?(src)
      return false if src.match?(/\A(?:javascript|data|blob|file):/i)
      return true if src.match?(%r{\Ahttps?://}i)
      return true if src.start_with?("/") && !src.start_with?("//")

      false
    end

    def gif_src?(src)
      src.to_s.match?(/\.gif(?:\?|#|$)/i)
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
