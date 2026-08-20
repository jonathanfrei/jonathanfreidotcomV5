# frozen_string_literal: true

require "json"

# Book collections: nested Markdown under _books/<book-slug>/ becomes a
# navigable book with stable slug permalinks, computed display numbers,
# recursive TOC data, and prev/next links. Filename and directory prefixes
# such as 001- and 002a- are sort keys only.
#
# Each directory is a content container. Its first directly contained Markdown
# file is the landing page for that directory; subsequent files and directories
# are its children. This convention is recursive and has no hard-coded depth.
#
# The hamburger TOC is not inlined into every chapter. Each book emits
# /books/<slug>/toc.json for book-nav.js. The title page still receives an
# in-article HTML TOC through book_toc.

module Jekyll
  module Books
    COLLECTION = "books"
    PREFIX_RE = /\A(\d+)([A-Za-z]*)-(.+)\z/.freeze

    module_function

    def book_docs(site)
      collection = site.collections[COLLECTION]
      return [] unless collection

      collection.docs
    end

    def posix(path)
      path.to_s.tr("\\", "/")
    end

    def relative_under_books(doc)
      relative = posix(doc.relative_path)
      relative = relative.sub(%r{\A_#{COLLECTION}/}, "")
      relative.sub(%r{\.[^./]+\z}, "")
    end

    # "002a-i-everyone-lies" becomes:
    # { int: 2, suffix: "a", slug: "i-everyone-lies" }
    def parse_segment(segment)
      name = segment.to_s
      if (match = PREFIX_RE.match(name))
        {
          int: match[1].to_i,
          suffix: match[2].to_s.downcase,
          slug: match[3].to_s
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

      basename = File.basename(posix(doc.relative_path), ".*")
      parse_segment(basename)[:slug]
    end

    def book_id_for(doc)
      relative_under_books(doc).split("/").first
    end

    def permalink_for(doc)
      parts = relative_under_books(doc).split("/")
      book_id = parts.first
      segments = [book_id]

      parts[1..].each do |part|
        slug = parse_segment(part)[:slug]
        segments << slug unless segments.last == slug
      end

      file_slug = slug_for(doc)
      segments << file_slug unless segments.last == file_slug
      "/#{COLLECTION}/#{segments.join('/')}"
    end

    def apply_permalink!(doc)
      return unless doc.collection && doc.collection.label == COLLECTION

      doc.data["book_id"] = book_id_for(doc)
      doc.data["slug"] = slug_for(doc)

      # An author-supplied permalink always wins.
      return unless doc.data["permalink"].to_s.strip.empty?

      doc.data["permalink"] = permalink_for(doc)
    end

    def enrich!(site)
      docs = book_docs(site)
      return if docs.empty?

      docs.each { |doc| apply_permalink!(doc) }

      docs.group_by { |doc| doc.data["book_id"] }.each do |book_id, book_pages|
        enrich_book!(site, book_id, book_pages)
      end

      duplicate_urls = docs.map(&:url).tally.select { |_, count| count > 1 }.keys
      return if duplicate_urls.empty?

      raise Jekyll::Errors::FatalException,
            "Book permalink collision(s): #{duplicate_urls.join(', ')}"
    end

    def enrich_book!(site, book_id, docs)
      entries = docs.map { |doc| entry_for(doc) }
      nodes = build_nodes(entries)

      raise Jekyll::Errors::FatalException, "Book #{book_id} has no pages" if nodes.empty?

      home_node = nodes.first
      unless home_node[:kind] == :file
        raise Jekyll::Errors::FatalException,
              "Book #{book_id} must start with a root Markdown file (book home), not a folder"
      end

      home = home_node[:entry][:doc]
      index_flag = home.data.key?("index") ? !!home.data["index"] : true
      listed_flag = home.data.key?("listed") ? !!home.data["listed"] : index_flag

      reading = []
      toc = []

      home.data["nav_number"] = ""
      home.data["is_book_home"] = true
      apply_flags!(home, home, index_flag, listed_flag, book_id)
      reading << home
      toc << toc_item(home, [])

      nodes.drop(1).each_with_index do |node, index|
        toc << materialize_node!(
          node,
          (index + 1).to_s,
          home,
          index_flag,
          listed_flag,
          book_id,
          reading
        )
      end

      validate_sibling_slugs!(book_id, docs)
      assign_reading_links!(reading, home, index_flag, listed_flag, book_id)

      # In-article TOC is title-page only. Overlay navigation loads toc.json.
      home.data["book_toc"] = toc
      assign_toc_relationships!(toc)

      site.data["book_nav"] ||= {}
      site.data["book_nav"][book_id] = {
        "id" => book_id,
        "title" => home.data["title"].to_s,
        "url" => home.url,
        "noindex" => !index_flag,
        "items" => toc.map { |item| json_item(item) }
      }
    end

    # Build a recursively nested tree from entry directory paths. At each
    # depth, directly contained files and immediate child directories become
    # sibling nodes and are sorted together by their numeric prefixes.
    def build_nodes(entries, depth = 0)
      direct_files, nested_entries = entries.partition do |entry|
        entry[:dir_parts].length == depth
      end

      nodes = direct_files.map do |entry|
        { kind: :file, entry: entry, sort: entry[:sort] }
      end

      nested_entries.group_by { |entry| entry[:dir_parts][depth] }.each do |folder, children|
        nodes << {
          kind: :folder,
          folder: folder,
          entries: build_nodes(children, depth + 1),
          sort: sort_key(folder)
        }
      end

      nodes.sort_by { |node| node[:sort] }
    end

    # Convert one tree node into TOC data and append its pages to reading order.
    # A folder consumes one number. Its landing page receives that number, and
    # every later child receives a dotted number beneath it.
    def materialize_node!(node, number, home, index_flag, listed_flag, book_id, reading)
      if node[:kind] == :file
        doc = node[:entry][:doc]
        number_doc!(doc, number, home, index_flag, listed_flag, book_id)
        reading << doc
        return toc_item(doc, [])
      end

      children = node[:entries]
      landing_node = children.first
      unless landing_node && landing_node[:kind] == :file
        folder_path = folder_path_for(book_id, node, landing_node)
        raise Jekyll::Errors::FatalException,
              "Book folder #{folder_path} must start with a directly contained Markdown file"
      end

      landing = landing_node[:entry][:doc]
      number_doc!(landing, number, home, index_flag, listed_flag, book_id)
      reading << landing

      child_items = children.drop(1).each_with_index.map do |child, index|
        materialize_node!(
          child,
          "#{number}.#{index + 1}",
          home,
          index_flag,
          listed_flag,
          book_id,
          reading
        )
      end

      toc_item(landing, child_items)
    end

    def folder_path_for(book_id, node, landing_node)
      if landing_node && landing_node[:kind] == :file
        directory = File.dirname(relative_under_books(landing_node[:entry][:doc]))
        return directory unless directory == "."
      end

      "#{book_id}/#{node[:folder]}"
    end

    def validate_sibling_slugs!(book_id, docs)
      sibling_slugs = Hash.new { |hash, key| hash[key] = [] }

      docs.each do |doc|
        parent_directory = File.dirname(relative_under_books(doc))
        sibling_slugs[parent_directory] << doc.data["slug"]
      end

      sibling_slugs.each do |directory, slugs|
        duplicates = slugs.tally.select { |_, count| count > 1 }.keys
        next if duplicates.empty?

        raise Jekyll::Errors::FatalException,
              "Duplicate book slugs in #{book_id}/#{directory}: #{duplicates.join(', ')}"
      end
    end

    def assign_reading_links!(reading, home, index_flag, listed_flag, book_id)
      reading.each_with_index do |doc, index|
        doc.data["book_prev"] = index.positive? ? reading[index - 1] : nil
        doc.data["book_next"] = reading[index + 1]
        doc.data["book_home"] = home
        doc.data["is_book_home"] = (doc == home)
        doc.data["book_toc_url"] = "/#{COLLECTION}/#{book_id}/toc.json"
        apply_flags!(doc, home, index_flag, listed_flag, book_id)
      end
    end

    # Populate book_parent and book_children recursively at every TOC depth.
    def assign_toc_relationships!(items, parent = nil)
      items.each do |item|
        page = item["page"]
        children = item["children"] || []
        child_pages = children.map { |child| child["page"] }

        page.data["book_parent"] = parent if parent
        page.data["book_children"] = child_pages
        assign_toc_relationships!(children, page)
      end
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
        existing = site.pages.find { |page| page.data["permalink"] == permalink }

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
      relative = relative_under_books(doc)
      parts = relative.split("/")
      directory_parts = parts[1...-1] || []
      basename = File.basename(posix(doc.relative_path), ".*")

      {
        doc: doc,
        dir_parts: directory_parts,
        sort: sort_key(basename, doc.data["order"]),
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
