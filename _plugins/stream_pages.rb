# frozen_string_literal: true

# Paginated blended /blog stream and helpers for other 20-item lists (#186).
module Jekyll
  module StreamPagination
    module_function

    def per_page(site)
      n = site.config.dig("pagination", "per_page").to_i
      n.positive? ? n : 20
    end

    def total_pages(size, per)
      pages = (size.to_f / per).ceil
      pages < 1 ? 1 : pages
    end

    def path_for(base, page_num)
      page_num <= 1 ? base : "#{base}/page/#{page_num}/"
    end

    def trail(page_num, pages, base, before: 2, after: 2)
      from = [page_num - before, 1].max
      to = [page_num + after, pages].min
      (from..to).map { |n| { "num" => n, "path" => path_for(base, n) } }
    end

    def paginator(page_num, total, per, base, posts: nil)
      pages = total_pages(total, per)
      {
        "page" => page_num,
        "per_page" => per,
        "posts" => posts,
        "total_posts" => total,
        "total_pages" => pages,
        "previous_page" => page_num > 1 ? page_num - 1 : nil,
        "previous_page_path" => page_num > 1 ? path_for(base, page_num - 1) : nil,
        "next_page" => page_num < pages ? page_num + 1 : nil,
        "next_page_path" => page_num < pages ? path_for(base, page_num + 1) : nil,
        "first_page_path" => base,
        "page_trail" => trail(page_num, pages, base)
      }
    end

    def apply_page!(page, items, page_num, per, base)
      slice = items[((page_num - 1) * per), per] || []
      page.data["stream_items"] = slice
      page.data["paginator"] = paginator(page_num, items.size, per, base, posts: slice)
    end
  end

  class StreamGeneratedPage < PageWithoutAFile
    def initialize(site, dir, name, data, content)
      super(site, site.source, dir, name)
      self.data = data
      self.content = content
    end
  end

  class StreamPagesGenerator < Generator
    safe true
    priority :low

    def generate(site)
      stream = site.data["site_stream"] || []
      blog = site.pages.find { |page| blog_page?(page) }
      return unless blog

      per = StreamPagination.per_page(site)
      base = "/blog"
      StreamPagination.apply_page!(blog, stream, 1, per, base)

      pages = StreamPagination.total_pages(stream.size, per)
      return if pages <= 1

      content = blog.content
      layout = blog.data["layout"]
      title = blog.data["title"]
      description = blog.data["description"]

      (2..pages).each do |num|
        dir = "blog/page/#{num}"
        data = {
          "layout" => layout,
          "permalink" => StreamPagination.path_for(base, num),
          "title" => "#{title} – page #{num} of #{pages}",
          "description" => description,
          "pagination" => { "enabled" => false }
        }
        page = StreamGeneratedPage.new(site, dir, "index.html", data, content)
        StreamPagination.apply_page!(page, stream, num, per, base)
        site.pages << page
      end
    end

    def blog_page?(page)
      url = normalize(page)
      url == "/blog"
    end

    def normalize(page)
      raw = page.data["permalink"] || page.url
      raw.to_s.sub(%r{/\z}, "").sub(/\.html\z/, "")
    end
  end
end
