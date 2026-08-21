# frozen_string_literal: true

require "json"

# Book collections: nested markdown under _books/<book-slug>/ becomes a
# navigable book with stable slug permalinks, computed display numbers,
# and prev/next links. Filename prefixes (001-, 002a-) are sort keys only.
#
# The hamburger TOC is not inlined into every chapter (that duplicated ~200
# links per page). Each book emits /books/<slug>/toc.json; book-nav.js fetches
# it. The title page still renders an in-article HTML TOC.

module Jekyll
  module Books
    COLLECTION = "books"
    PREFIX_RE = /\A(\d+)([A-Za-z]*)-(.+)\z/.freeze

    module_function

    def book_docs(site)
      coll = site.collections[COLLECTION]
      return [] unless coll

      coll.docs
    end

    def posix(path)
      path.to_s.tr("\\", "/")
    end

    def relative_under_books(doc)
      rel = posix(doc.relative_path)
      rel = rel.sub(%r{\A_#{COLLECTION}/}, "")
      rel.sub(%r{\.[^./]+\z}, "")
    end

    # "002a-i-everyone-lies" => { int: 2, suffix: "a", slug: "i-everyone-lies" }
    def parse_segment(segment)
      name = segment.to_s
      if (m = PREFIX_RE.match(name))
        {
          int: m[1].to_i,
          suffix: m[2].to_s.downcase,
          slug: m[3].to_s
        }
      else
        {
          int: 1_000_000,
          suffix: "",
          slug: name
        }
      end
    end

    def sort_key(segment, order_override = nil)
      if order_override && !order_override.to_s.strip.empty?
        [Float(order_override), ""]
      else
        parsed = parse_segment(segment)
        [parsed[:int], parsed[:suffix]]
      end
    rescue ArgumentError
      parsed = parse_segment(segment)
      [parsed[:int], parsed[:suffix]]
    end

    def slug_for(doc)
      explicit = doc.data["slug"].to_s.strip
      return explicit unless explicit.empty?

      base = File.basename(posix(doc.relative_path), ".*")
      parse_segment(base)[:slug]
    end

    def book_id_for(doc)
      relative_under_books(doc).split("/").first
    end

    def permalink_for(doc)
      rel = relative_under_books(doc)
      parts = rel.split("/")
      book = parts.first
      segs = [book]
      parts[1..].each do |part|
        slug = parse_segment(part)[:slug]
        segs << slug unless segs.last == slug
      end
      file_slug = slug_for(doc)
      segs << file_slug unless segs.last == file_slug
      "/#{COLLECTION}/#{segs.join('/')}"
    end

    def apply_permalink!(doc)
      return unless doc.collection && doc.collection.label == COLLECTION

      doc.data["book_id"] = book_id_for(doc)
      doc.data["slug"] = slug_for(doc)
      # Author permalink still wins.
      return if doc.data["permalink"].to_s.strip != ""

      doc.data["permalink"] = permalink_for(doc)
    end

    def enrich!(site)
      docs = book_docs(site)
      return if docs.empty?

      docs.each { |doc| apply_permalink!(doc) }

      grouped = docs.group_by { |d| d.data["book_id"] }
      grouped.each do |book_id, book_pages|
        enrich_book!(site, book_id, book_pages)
      end

      urls = docs.map { |d| d.url }
      dupes = urls.tally.select { |_, n| n > 1 }.keys
      unless dupes.empty?
        raise Jekyll::Errors::FatalException,
              "Book permalink collision(s): #{dupes.join(', ')}"
      end
    end

    def enrich_book!(site, book_id, docs)
      entries = docs.map { |doc| entry_for(doc) }

      root_files, in_folders = entries.partition { |e| e[:dir_parts].empty? }
      root_files.sort_by! { |e| e[:sort] }

      folders = {}
      in_folders.each do |e|
        folder = e[:dir_parts].first
        folders[folder] ||= []
        folders[folder] << e
      end
      folders.each_value { |list| list.sort_by! { |e| e[:sort] } }

      top = []
      root_files.each { |e| top << { kind: :file, entry: e, sort: e[:sort] } }
      folders.each do |folder, list|
        top << { kind: :folder, folder: folder, entries: list, sort: sort_key(folder) }
      end
      top.sort_by! { |n| n[:sort] }

      raise Jekyll::Errors::FatalException, "Book #{book_id} has no pages" if top.empty?

      home_node = top.first
      unless home_node[:kind] == :file
        raise Jekyll::Errors::FatalException,
              "Book #{book_id} must start with a root markdown file (book home), not a folder"
      end

      home = home_node[:entry][:doc]
      index_flag = home.data.key?("index") ? !!home.data["index"] : true
      listed_flag =
        if home.data.key?("listed")
          !!home.data["listed"]
        else
          index_flag
        end

      reading = []
      toc = []

      home.data["nav_number"] = ""
      home.data["is_book_home"] = true
      reading << home
      toc << toc_item(home, [])

      chapter_i = 0
      top.drop(1).each do |node|
        chapter_i += 1
        if node[:kind] == :file
          doc = node[:entry][:doc]
          number_doc!(doc, chapter_i.to_s, home, index_flag, listed_flag, book_id)
          reading << doc
          toc << toc_item(doc, [])
        else
          kids = node[:entries]
          chapter_home = kids.first[:doc]
          number_doc!(chapter_home, chapter_i.to_s, home, index_flag, listed_flag, book_id)
          reading << chapter_home
          child_items = []
          kids.drop(1).each_with_index do |child, idx|
            section = child[:doc]
            number_doc!(
              section,
              "#{chapter_i}.#{idx + 1}",
              home,
              index_flag,
              listed_flag,
              book_id
            )
            reading << section
            child_items << toc_item(section, [])
          end
          toc << toc_item(chapter_home, child_items)
        end
      end

      sibling_slugs = Hash.new { |h, k| h[k] = [] }
      docs.each do |doc|
        parent_dir = File.dirname(relative_under_books(doc))
        sibling_slugs[parent_dir] << doc.data["slug"]
      end
      sibling_slugs.each do |dir, slugs|
        dup = slugs.tally.select { |_, n| n > 1 }.keys
        next if dup.empty?

        raise Jekyll::Errors::FatalException,
              "Duplicate book slugs in #{book_id}/#{dir}: #{dup.join(', ')}"
      end

      reading.each_with_index do |doc, i|
        doc.data["book_prev"] = i.positive? ? reading[i - 1] : nil
        doc.data["book_next"] = reading[i + 1]
        doc.data["book_home"] = home
        doc.data["is_book_home"] = (doc == home)
        doc.data["book_toc_url"] = "/#{COLLECTION}/#{book_id}/toc.json"
        apply_flags!(doc, home, index_flag, listed_flag, book_id)
      end

      # In-article TOC is title-page only. Overlay nav loads toc.json.
      home.data["book_toc"] = toc

      toc.each do |item|
        parent = item["page"]
        children = item["children"].map { |c| c["page"] }
        parent.data["book_children"] = children
        children.each { |c| c.data["book_parent"] = parent }
      end

      site.data["book_nav"] ||= {}
      site.data["book_nav"][book_id] = {
        "id" => book_id,
        "title" => home.data["title"].to_s,
        "url" => home.url,
        "noindex" => !index_flag,
        "items" => toc.map { |item| json_item(item) }
      }
    end

    def json_item(item)
      doc = item["page"]
      children = item["children"] || []
      node = {
        "title" => doc.data["title"].to_s,
        "url" => doc.url,
        "slug" => doc.data["slug"].to_s,
        "num" => doc.data["nav_number"].to_s
      }
      node["children"] = children.map { |child| json_item(child) } unless children.empty?
      node
    end

    def emit_toc_pages!(site)
      (site.data["book_nav"] || {}).each do |book_id, payload|
        permalink = "/books/#{book_id}/toc.json"
        json = toc_json_body(payload)
        existing = site.pages.find { |p| p.data["permalink"] == permalink }
        if existing
          existing.content = json
        else
          site.pages << TocJson.new(site, book_id, payload, json)
        end
      end
    end

    def toc_json_body(payload)
      body = payload.dup
      body.delete("noindex")
      JSON.generate(body)
    end

    def entry_for(doc)
      rel = relative_under_books(doc)
      parts = rel.split("/")
      dir_parts = parts[1..-2] || []
      base = File.basename(posix(doc.relative_path), ".*")
      {
        doc: doc,
        dir_parts: dir_parts,
        sort: sort_key(base, doc.data["order"]),
        slug: slug_for(doc)
      }
    end

    def toc_item(doc, children)
      { "page" => doc, "children" => children }
    end

    def number_doc!(doc, number, home, index_flag, listed_flag, book_id)
      doc.data["nav_number"] = number
      doc.data["is_book_home"] = false
      apply_flags!(doc, home, index_flag, listed_flag, book_id)
    end

    def apply_flags!(doc, home, index_flag, listed_flag, book_id)
      doc.data["book_id"] = book_id
      doc.data["book_noindex"] = !index_flag
      doc.data["book_listed"] = listed_flag
      doc.data["book_title"] = home.data["title"]
      # Visible author comes from book-home front matter only (#277).
      # There is no collection default; empty home author stays empty.
      home_author = home.data["author"].to_s.strip
      doc.data["author"] = home_author unless home_author.empty?
      return if index_flag

      doc.data["sitemap"] = false
      doc.data["robots"] = "noindex, nofollow"
    end

    class TocJson < Jekyll::PageWithoutAFile
      def initialize(site, book_id, payload, json)
        super(site, site.source, File.join("books", book_id), "toc.json")
        self.data["layout"] = nil
        self.data["sitemap"] = false
        self.data["permalink"] = "/books/#{book_id}/toc.json"
        self.data["robots"] = "noindex, nofollow" if payload["noindex"]
        self.content = json
      end

      def render_with_liquid?
        false
      end
    end

    class Generator < Jekyll::Generator
      safe true
      priority :high

      def generate(site)
        Jekyll::Books.enrich!(site)
        Jekyll::Books.emit_toc_pages!(site)
      end
    end
  end
end

Jekyll::Hooks.register :documents, :post_init do |doc|
  Jekyll::Books.apply_permalink!(doc)
end

