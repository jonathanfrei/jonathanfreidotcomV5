# frozen_string_literal: true

# Do not materialize /tags/:name or /categories/:name archives.
# Discovery is client-side search (?tag= / ?category=).
# prune_*_archive_pages! remains a backstop.

return unless defined?(Jekyll::PaginateV2::AutoPages)

module Jekyll
  module PaginateV2::AutoPages
    class << self
      alias_method :autopage_create_unfiltered, :autopage_create unless method_defined?(:autopage_create_unfiltered)

      def autopage_create(autopage_config, pagination_config, posts_to_use, configkey_name, indexkey_name, createpage_lambda)
        if configkey_name.to_s == "tags"
          Jekyll.logger.info "AutoPages:", "skipped all tag archives (search URLs, #209)"
          return
        end
        if configkey_name.to_s == "categories"
          Jekyll.logger.info "AutoPages:", "skipped all category archives (search URLs)"
          return
        end

        autopage_create_unfiltered(
          autopage_config, pagination_config, posts_to_use,
          configkey_name, indexkey_name, createpage_lambda
        )
      end
    end
  end
end
