# frozen_string_literal: true

# Do not ask jekyll-paginate-v2 to materialize tag archives with fewer than
# tag_archive_min_posts posts. prune_singleton_tag_pages! remains a backstop.

return unless defined?(Jekyll::PaginateV2::AutoPages)

module Jekyll
  module LimitTagAutopages
    module_function

    def min_posts(posts)
      site = posts.find { |doc| doc.respond_to?(:site) }&.site
      n = site&.config&.[]("tag_archive_min_posts").to_i
      n = NormalizeTags::MIN_TAG_ARCHIVE_POSTS if n <= 0
      n
    end

    def tag_counts(posts)
      counts = Hash.new(0)
      posts.each do |post|
        next unless post.respond_to?(:data)

        Array(post.data["tags"]).each do |tag|
          key = tag.to_s.downcase.strip
          counts[key] += 1 unless key.empty?
        end
      end
      counts
    end
  end
end

module Jekyll
  module PaginateV2::AutoPages
    class << self
      alias_method :autopage_create_unfiltered, :autopage_create unless method_defined?(:autopage_create_unfiltered)

      def autopage_create(autopage_config, pagination_config, posts_to_use, configkey_name, indexkey_name, createpage_lambda)
        if configkey_name.to_s == "tags"
          docs = Array(posts_to_use)
          min = Jekyll::LimitTagAutopages.min_posts(docs)
          counts = Jekyll::LimitTagAutopages.tag_counts(docs)
          skipped = 0
          filtered = lambda do |*args|
            tag = args[3].to_s.downcase.strip
            if counts[tag] < min
              skipped += 1
              next
            end

            createpage_lambda.call(*args)
          end
          result = autopage_create_unfiltered(
            autopage_config, pagination_config, posts_to_use,
            configkey_name, indexkey_name, filtered
          )
          Jekyll.logger.info "AutoPages:",
                             "skipped #{skipped} singleton tag page(s) (min #{min})"
          return result
        end

        autopage_create_unfiltered(
          autopage_config, pagination_config, posts_to_use,
          configkey_name, indexkey_name, createpage_lambda
        )
      end
    end
  end
end
