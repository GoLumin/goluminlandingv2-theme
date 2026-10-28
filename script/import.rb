# frozen_string_literal: true

# golumin.io's content, from the Astro site into this CMS: the collections
# (services, case studies, posts, roles, landing pages, clients, quotes,
# the team), the block types its pages are composed of and every page, the
# nav, footer, proof and ad-landing globals, the forms, the media, the
# redirects and Settings › General and Branding. Run inside a Libre Publish
# checkout with the theme linked:
#
#   bin/rails runner themes/goluminlandingv2/script/import.rb
#   ASTRO=/path/to/goluminlandingv2 bin/rails runner themes/goluminlandingv2/script/import.rb
#
# The data files (src/data/*.ts) come from script/astro-data.json
# (script/export-astro.ts); posts and images are read from the Astro
# checkout (ASTRO, by default the sibling ../goluminlandingv2). Safe to run
# again: everything is matched by slug, path or file name and updated.
# Published, as the Astro site shows it; clients not cleared for public
# mention (show: false) come in as drafts.
require "json"
require "yaml"

module GoluminImport
  ROOT = Pathname(__dir__)
  ASTRO = Pathname(ENV.fetch("ASTRO", ROOT.join("../../goluminlandingv2").to_s)).expand_path
  DATA = JSON.parse(ROOT.join("astro-data.json").read)
  FOLDER = "/golumin"

  module_function

  # ── Field schemas, inferred from the content they hold ─────────────────────

  def snake(value)
    case value
    when Hash then value.to_h { |k, v| [k.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase, snake(v)] }
    when Array then value.map { snake(it) }
    else value
    end
  end

  # Field definitions for a list of sample hashes: every key any of them has,
  # typed by what it holds. `overrides` (by name, "a.b" for nested) wins.
  def fields_for(samples, overrides = {}, prefix = nil)
    samples = Array(samples).grep(Hash)
    keys = samples.flat_map(&:keys).uniq
    keys.map do |key|
      path = [prefix, key].compact.join(".")
      values = samples.map { it[key] }.compact
      field = {"name" => key, "label" => key.humanize}.merge(type_for(values, overrides, path))
      field = field.merge("type" => "asset") if %w[integer string].include?(field["type"]) && key.match?(IMAGE_NAMES)
      field.merge(overrides[path].to_h.except("of"))
    end
  end

  # Fields by these names hold an asset's id.
  IMAGE_NAMES = /(\A|_)(image|photo|logo|screenshot|badge|art)(_id)?\z/

  def type_for(values, overrides, path)
    sample = values.find { !it.nil? && it != [] }
    case sample
    when nil then {"type" => "string"}
    when true, false then {"type" => "boolean"}
    when Integer then values.all?(Integer) ? {"type" => "integer"} : {"type" => "string"}
    when Float then {"type" => "string"}
    when Hash
      return {"type" => "link"} if sample.keys.sort == %w[kind value]

      {"type" => "group", "of" => fields_for(values, overrides, path)}
    when Array
      if sample.first.is_a?(Hash)
        {"type" => "repeater", "of" => fields_for(values.flatten(1), overrides, path)}
      else
        {"type" => "string_list"}
      end
    when String
      (values.any? { it.to_s.length > 90 || it.to_s.include?("\n") }) ? {"type" => "text"} : {"type" => "string"}
    else {"type" => "string"}
    end
  end

  # Data held to its fields' types: a number in a text field (a rate of 15
  # beside one of 6.6) as text.
  def conform(data, fields)
    return data unless data.is_a?(Hash)

    fields = Array(fields).index_by { it["name"] }
    data.to_h do |key, value|
      field = fields[key]
      value = case field&.dig("type")
      when "string", "text" then value.is_a?(Numeric) ? value.to_s : value
      when "group" then conform(value, field["of"])
      when "repeater" then Array(value).map { conform(it, field["of"]) }
      else value
      end
      [key, value]
    end
  end

  # Numbers the inference stores as text (a rate of 6.6) go in as text.
  def stringify_floats(value)
    case value
    when Hash then value.transform_values { stringify_floats(it) }
    when Array then value.map { stringify_floats(it) }
    when Float then value.to_s
    else value
    end
  end

  # A link field's value: a URL, an anchor or an address on the site.
  def link(value) = {"kind" => "url", "value" => value}

  # ── Media ──────────────────────────────────────────────────────────────────

  # An asset for a file of the Astro site's public/ directory (or a URL),
  # with its alt text: matched by file name, so a second run reuses it.
  def asset(path, alt:)
    @assets ||= {}
    @assets[path] ||= begin
      filename = (path.start_with?("http") ? File.basename(URI(path).path) : path.delete_prefix("/").tr("/", "-"))
      existing = Asset.where(folder: FOLDER).joins(file_attachment: :blob).find_by(active_storage_blobs: {filename: filename})
      if existing
        existing.update!(alt: alt) if existing.alt != alt
        existing
      else
        io = path.start_with?("http") ? StringIO.new(Net::HTTP.get(URI(path))) : ASTRO.join("public", path.delete_prefix("/")).open("rb")
        record = Asset.create!(file: {io:, filename:}, folder: FOLDER, alt:, name: File.basename(filename, ".*").humanize)
        puts "  asset #{filename}"
        record
      end
    end
    @assets[path].id.to_s
  end

  # ── Records ────────────────────────────────────────────────────────────────

  # A block type from the blocks that use it: fields inferred from their data
  # (overrides for links, images, choices), defaults from the first.
  def block_type(slug, label:, category:, description:, blocks:, overrides: {}, icon: "LayoutTemplate")
    samples = blocks.map { it["data"] }
    type = BlockType.find_or_initialize_by(slug: slug)
    type.update!(label:, category:, description:, icon:, version: 1, fields: fields_for(samples, overrides), defaults: samples.first)
    type
  end

  def collection(slug, name:, fields:, icon: "Folder", blocks: false, tags: nil)
    record = Collection.find_or_initialize_by(slug: slug)
    record.update!(name:, schema: {"fields" => fields}, enable_blocks: blocks, icon:, tags_collection: tags)
    record
  end

  def entry(collection, slug, title:, frontmatter: {}, status: "published", seo: {}, body: nil, blocks: nil, published_at: nil, tags: nil)
    record = collection.entries.find_or_initialize_by(slug: slug)
    attrs = {title:, frontmatter: conform(stringify_floats(frontmatter), collection.fields), status:, seo:, locale: "en"}
    attrs[:body_markdown] = body if body
    attrs[:blocks] = blocks if blocks
    attrs[:published_at] = published_at || record.published_at || Time.current if status == "published"
    attrs[:tags] = tags if tags
    record.update!(attrs)
    record
  end

  def global(slug, name:, data:, fields: nil, overrides: {})
    record = Global.find_or_initialize_by(slug: slug)
    data = stringify_floats(data)
    fields ||= fields_for([data], overrides)
    record.update!(name:, data: conform(data, fields), schema: {"fields" => fields})
    record
  end

  def page(path, title:, blocks:, seo: {}, status: "published")
    record = Page.find_or_initialize_by(path: path, parent_id: nil)
    record.update!(slug: path, title:, locale: "en", status:, seo:,
      blocks: blocks.map { {"type" => it["type"], "version" => 1, "data" => conform(stringify_floats(it["data"]), BlockType.find_by(slug: it["type"])&.fields)} })
    record.update!(published_at: Time.current) if status == "published" && record.respond_to?(:published_at) && record.published_at.nil?
    record
  end

  def seo(title, description, noindex: false)
    {"meta_title" => title, "meta_description" => description, "noindex" => (true if noindex)}.compact
  end
end

load GoluminImport::ROOT.join("import/content.rb").to_s
load GoluminImport::ROOT.join("import/pages.rb").to_s

ActiveRecord::Base.transaction do
  GoluminImport::Content.run
  GoluminImport::Pages.run
end
puts "Done."
