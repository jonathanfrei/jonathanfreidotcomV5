# frozen_string_literal: true

require "open3"
require "time"

# Richer post metadata (issue #75) — automation-first, no archive front-matter edits.
#
# 1. last_modified_at
#    - Prefer explicit front matter (intentional revisions).
#    - Else set from git (last commit that touched the file) in one bulk log walk.
#    - Used for Schema.org dateModified, jekyll-seo-tag, jekyll-sitemap lastmod.
#    - UI "Updated …" only when meaningfully later than published (see layout).
#
# 2. word_count + reading_time (minutes at ~200 wpm)
#    - Computed from Markdown body; no front matter required.
#
# Config (_config.yml):
#   post_metadata:
#     git_last_modified: true   # false skips git (faster local / no .git)
#     words_per_minute: 200
module Jekyll
  module PostMetadata
    module_function

    DEFAULTS = {
      "git_last_modified" => true,
      "words_per_minute" => 200
    }.freeze

    def enrich!(site)
      cfg = DEFAULTS.merge(site.config["post_metadata"] || {})
      mtime_map = cfg["git_last_modified"] ? git_last_modified_map(site) : {}

      site.posts.docs.each do |post|
        apply_last_modified!(post, mtime_map)
        apply_reading_stats!(post, cfg)
      end
    end

    def apply_last_modified!(post, mtime_map)
      existing = post.data["last_modified_at"]
      if existing && !existing.to_s.strip.empty?
        # Author-set revision stamp — eligible for visible "Updated" UI.
        post.data["last_modified_at"] = coerce_time(existing) || existing
        post.data["last_modified_explicit"] = true
        return
      end

      post.data["last_modified_explicit"] = false

      key = normalize_repo_path(post.relative_path)
      iso = mtime_map[key]
      return unless iso

      t = coerce_time(iso)
      # Git-derived: machines only (schema, SEO, sitemap). Not shown as
      # "Updated" in the byline — archive imports would falsely look revised.
      post.data["last_modified_at"] = t if t
    end

    def apply_reading_stats!(post, cfg)
      wpm = (cfg["words_per_minute"] || 200).to_i
      wpm = 200 if wpm <= 0

      words = word_count(post.content)
      minutes = [(words.to_f / wpm).ceil, 1].max

      post.data["word_count"] = words
      post.data["reading_time"] = minutes
    end

    def word_count(markdown)
      text = markdown.to_s.dup
      # Fenced code, inline code, images, HTML tags — keep link labels
      text.gsub!(/```.*?```/m, " ")
      text.gsub!(/`[^`]*`/, " ")
      text.gsub!(/!\[[^\]]*\]\([^)]*\)/, " ")
      text.gsub!(/\[([^\]]*)\]\([^)]*\)/, '\1')
      text.gsub!(/<[^>]+>/, " ")
      text.gsub!(/[#>*_\-|]+/, " ")
      text.split(/\s+/).reject(&:empty?).size
    end

    # Single git log walk: first time a path appears is its newest commit (newest first).
    def git_last_modified_map(site)
      root = site.source
      return {} unless git_repo?(root)

      cmd = [
        "git", "-C", root,
        "log", "--format=%cI", "--name-only",
        "--diff-filter=ACDMR", "--", "_posts"
      ]
      out, status = Open3.capture2(*cmd)
      return {} unless status.success?

      map = {}
      current_date = nil
      out.each_line do |line|
        line = line.strip
        next if line.empty?

        if line.match?(/\A\d{4}-\d{2}-\d{2}T/)
          current_date = line
          next
        end
        next unless current_date

        path = normalize_repo_path(line)
        next unless path.start_with?("_posts/")
        next if map.key?(path)

        map[path] = current_date
      end
      map
    rescue StandardError => e
      Jekyll.logger.warn "PostMetadata:", "git last_modified skipped (#{e.class}: #{e.message})"
      {}
    end

    def git_repo?(root)
      File.directory?(File.join(root, ".git")) ||
        system("git", "-C", root, "rev-parse", "--is-inside-work-tree",
               out: File::NULL, err: File::NULL)
    end

    def normalize_repo_path(path)
      path.to_s.tr("\\", "/").sub(%r{\A\./}, "")
    end

    def coerce_time(value)
      case value
      when Time
        value
      when DateTime
        value.to_time
      when Date
        value.to_time
      else
        Time.parse(value.to_s)
      end
    rescue ArgumentError, TypeError
      nil
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  Jekyll::PostMetadata.enrich!(site)
end
