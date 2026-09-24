# frozen_string_literal: true

# Shared stubs so plugin files can be loaded without Jekyll itself.
# Each plugin is loaded with `require_relative` and only exercises pure
# functions — no network, no filesystem writes, no Jekyll build.

unless defined?(Jekyll)
  module Jekyll
    module Hooks
      def self.register(*_args, &_block); end
    end

    class PageWithoutAFile
      attr_accessor :data, :content

      def initialize(*_args)
        @data = {}
        @content = ""
      end
    end

    class Generator
      def self.safe(*_args); end
      def self.priority(*_args); end
    end

    module Errors
      class FatalException < StandardError; end
    end

    module Utils
      def self.slugify(value)
        value.to_s.downcase.strip.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
      end
    end

    def self.logger
      @logger ||= Object.new.tap do |o|
        def o.info(*_args); end
      end
    end
  end
end

require "minitest/autorun"
require "ostruct"
