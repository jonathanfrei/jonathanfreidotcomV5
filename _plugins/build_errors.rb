# frozen_string_literal: true

# Fail-soft content errors (#186): a single malformed post or link must not
# abort the site build. Record the path + reason, drop that document, and
# write _site/build-errors.log so the problem can be fixed before the next
# publish.

require "fileutils"

module Jekyll
  module BuildErrors
    module_function

    FORMAT_ERROR = /
      YAML|front\s*matter|Invalid\s*date|did\s*not\s*find|
      mapping\s*values|could\s*not\s*find\s*expected|Psych::
    /ix.freeze

    def list(site)
      site.data["build_errors"] ||= []
    end

    def record(site, path, message)
      entry = { "path" => path.to_s, "message" => message.to_s }
      list(site) << entry
      Jekyll.logger.warn "BuildErrors:", "#{path}: #{message}"
    end

    def write!(site)
      errors = list(site)
      dest = File.join(site.dest, "build-errors.log")
      FileUtils.mkdir_p(site.dest)
      if errors.empty?
        File.write(dest, "No content errors.\n")
        return
      end

      body = +"#{errors.size} skipped document(s):\n\n"
      errors.each { |entry| body << "#{entry['path']}: #{entry['message']}\n" }
      File.write(dest, body)
      Jekyll.logger.warn "BuildErrors:",
                         "#{errors.size} skipped document(s); see build-errors.log"
    end

    def format_error?(error)
      return true if defined?(Psych::SyntaxError) && error.is_a?(Psych::SyntaxError)
      return true if defined?(Psych::Exception) && error.is_a?(Psych::Exception)
      return true if defined?(Jekyll::Errors::InvalidYAMLFrontMatterError) &&
                     error.is_a?(Jekyll::Errors::InvalidYAMLFrontMatterError)
      return true if error.is_a?(ArgumentError) && error.message.match?(FORMAT_ERROR)

      error.message.match?(FORMAT_ERROR)
    end

    def drop_failed!(site)
      %w[posts links].each do |label|
        collection = site.collections[label]
        next unless collection

        collection.docs.reject! do |doc|
          next false unless doc.data["build_error"]

          true
        end
      end
    end
  end
end

module Jekyll
  class Document
    alias_method :read_without_build_errors, :read unless method_defined?(:read_without_build_errors)

    def read(opts = {})
      read_without_build_errors(opts)
    rescue StandardError => e
      label = collection&.label.to_s
      raise unless %w[posts links].include?(label)
      raise unless Jekyll::BuildErrors.format_error?(e)

      @data ||= {}
      data["build_error"] = e.message
      data["published"] = false
      self.content = ""
      Jekyll::BuildErrors.record(site, relative_path, e.message)
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  Jekyll::BuildErrors.drop_failed!(site)
end

Jekyll::Hooks.register :site, :post_write do |site|
  Jekyll::BuildErrors.write!(site)
end
