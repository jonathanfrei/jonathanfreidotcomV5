# frozen_string_literal: true

# Automatic drop caps on longer posts (issue #123).
#
# Default rule: file > 5 KB AND the first non-empty source line is prose
# longer than 100 characters. Front matter `drop_cap: true|false` wins.
#
# The first line is taken as written (not the first paragraph). Headings,
# images, HTML, quotes, lists, and fences never qualify — a 5 KB post that
# starts with a figure should not get a drop cap on a later paragraph.
module Jekyll
  module DropCap
    module_function

    MIN_FILE_BYTES = 5 * 1024
    MIN_FIRST_LINE = 100

    def apply!(site)
      site.posts.docs.each do |post|
        if post.data.key?("drop_cap")
          post.data["drop_cap"] = truthy?(post.data["drop_cap"])
          next
        end
        post.data["drop_cap"] = eligible?(post)
      end
    end

    def eligible?(post)
      return false if file_bytes(post) <= MIN_FILE_BYTES

      line = first_line(post.content)
      prose?(line) && line.length > MIN_FIRST_LINE
    end

    def first_line(markdown)
      markdown.to_s.each_line do |line|
        stripped = line.strip
        return stripped unless stripped.empty?
      end
      ""
    end

    def prose?(line)
      return false if line.nil? || line.empty?
      return false if line.start_with?("#", ">", "```", "~~~", "<", "![")
      return false if line.match?(/\A(-{3,}|\*{3,}|_{3,})\z/)
      return false if line.match?(/\A[-*+]\s+/)
      return false if line.match?(/\A\d+\.\s+/)
      return false if line.match?(%r{\Ahttps?://}i)
      return false if line.match?(/\A\[[^\]]+\]:\s+\S/)
      true
    end

    def file_bytes(post)
      path = post.path.to_s
      return File.size(path) if !path.empty? && File.file?(path)

      0
    end

    def truthy?(value)
      case value
      when true then true
      when false, nil then false
      else
        !%w[false no 0].include?(value.to_s.strip.downcase)
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  Jekyll::DropCap.apply!(site)
end
