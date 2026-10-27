# Takes the word "free" out of every record that feeds the public site, using
# the wording the approved redesign already settled on (script/launch/free-rules.json).
#
#   bin/rails runner script/launch/free-cleanup.rb            # report only, changes nothing
#   bin/rails runner script/launch/free-cleanup.rb --apply    # write
#
# Anything the rules do not cover is listed at the end rather than left quiet,
# so a missed phrase is visible instead of shipping.
require "json"

APPLY = ARGV.include?("--apply")
RULES = JSON.parse(File.read(File.expand_path("free-rules.json", __dir__)))["rules"]
WORD  = /\bfree\b/i

$changed = Hash.new { |h, k| h[k] = [] }
$leftover = []

def scrub(value, label, path = "")
  case value
  when String
    return value unless value =~ WORD
    after = value.dup
    RULES.each { |from, to| after = after.gsub(from, to) }
    $changed[label] << [path, value, after] if after != value
    after.scan(/.{0,45}\bfree\b.{0,45}/im) { $leftover << ["#{label} #{path}", it.gsub(/\s+/, " ").strip] }
    after
  when Hash
    value.each_with_object({}) { |(k, v), h| h[k] = scrub(v, label, "#{path}.#{k}") }
  when Array
    value.each_with_index.map { |v, i| scrub(v, label, "#{path}[#{i}]") }
  else
    value
  end
end

def sweep(record, label, fields)
  updates = {}
  fields.each do |f|
    before = record.public_send(f)
    after  = scrub(before, label, f.to_s)
    updates[f] = after unless after == before
  end
  return if updates.empty?

  if APPLY
    record.update_columns(updates.merge(updated_at: Time.current))
  end
end

Page.find_each { sweep(it, "page:#{it.path.presence || it.slug}[#{it.status}]", %i[title seo blocks]) }
CollectionEntry.find_each { sweep(it, "entry:#{it.collection.slug}/#{it.slug}[#{it.status}]", %i[title seo frontmatter blocks body_markdown]) }
Global.find_each { sweep(it, "global:#{it.slug}", %i[data]) }
Form.find_each { sweep(it, "form:#{it.slug}", %i[title submit_label success_message fields]) }
FormEmail.find_each { sweep(it, "formemail:#{it.form.slug}/#{it.kind}", %i[subject blocks]) }
Collection.find_each { sweep(it, "collection:#{it.slug}", %i[schema]) }

n = $changed.values.sum(&:size)
puts(APPLY ? "APPLIED #{n} edits across #{$changed.size} records\n\n" : "DRY RUN: #{n} edits across #{$changed.size} records (nothing written)\n\n")
$changed.sort.each do |label, edits|
  puts "=== #{label}"
  edits.each do |path, before, after|
    b = before.scan(/.{0,50}\bfree\b.{0,50}/im).map { it.gsub(/\s+/, " ").strip }
    puts "  #{path}"
    b.each { puts "    -  …#{it}…" }
    RULES.each { |from, to| puts "    +  #{from.inspect} -> #{to.inspect}" if before.include?(from) }
  end
  puts
end

if $leftover.any?
  puts "!! #{$leftover.size} occurrence(s) NO RULE COVERS:"
  $leftover.uniq.each { |where, snippet| puts "   #{where}\n     …#{snippet}…" }
else
  puts "No occurrence left uncovered."
end
