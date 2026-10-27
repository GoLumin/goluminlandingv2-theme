# Puts the redesign's content into a LOCAL CMS copy so the new site can be
# clicked through at its real URLs before anything is proposed to production.
#
#   bin/rails runner script/launch/preview-apply.rb
#
# Refuses to run unless the install looks local, because it writes straight to
# records without the approvals gate. Sources, all from this branch's own
# script/redesign/, nothing invented here:
#   pages/*.json     the redesign's pages, onto the live page each one replaces
#   globals.json     nav, footer and the ad_landing groups
#   entries/*.json   the three service entries' new fields
#   services.json    the service cards' copy
require "json"

base = Setting.get("general")["site_base_url"].to_s
abort "Refusing: site_base_url is #{base.inspect}, which is not local." unless base.match?(/localhost|127\.0\.0\.1/)

DIR = File.expand_path("../redesign", __dir__)
def read(rel) = JSON.parse(File.read(File.join(DIR, rel)))

# Which redesign page replaces which live page. Never renames a live page.
ONTO = {"home" => "home", "services" => "services", "results" => "work",
        "how-we-work" => "how-it-works", "contact" => "lets-talk",
        "careers" => "careers", "referrals" => "referrals"}
NEW  = {"tracking" => "tracking", "about" => "about"} # the only two new paths

log = []

ONTO.each do |file, slug|
  page = Page.find_by(slug: slug) or next log << "  ! no page #{slug}"
  body = read("pages/#{file}.json")["page"]
  page.update_columns(blocks: body["blocks"], seo: body["seo"].presence || page.seo, updated_at: Time.current)
  log << "  page /#{slug == "home" ? "" : slug}#{" " * [0, 18 - slug.size].max} <- pages/#{file}.json (#{body["blocks"].size} blocks)"
end

NEW.each do |file, slug|
  body = read("pages/#{file}.json")["page"]
  page = Page.find_or_initialize_by(slug: slug)
  page.assign_attributes(path: slug, title: body["title"], locale: "en",
                         blocks: body["blocks"], seo: body["seo"], status: "published")
  page.save!(validate: false)
  log << "  page /#{slug}#{" " * [0, 18 - slug.size].max} <- pages/#{file}.json (new, #{body["blocks"].size} blocks)"
end

read("globals.json").each do |key, value|
  slug, group = key.split(".", 2)
  g = Global.find_by(slug: slug) or next log << "  ! no global #{slug}"
  data = g.data.deep_dup
  group ? (data[group] = value) : (data = data.merge(value))
  g.update_columns(data: data, updated_at: Time.current)
  log << "  global #{key}"
end

services = Collection.find_by(slug: "services")
read("services.json").each do |slug, fields|
  e = services&.entries&.find_by(slug: slug) or next log << "  ! no services/#{slug}"
  e.update_columns(frontmatter: e.frontmatter.merge(fields), updated_at: Time.current)
  log << "  entry services/#{slug} <- services.json"
end
Dir[File.join(DIR, "entries", "*.json")].sort.each do |path|
  slug = File.basename(path, ".json")
  e = services&.entries&.find_by(slug: slug) or next log << "  ! no services/#{slug}"
  fm = JSON.parse(File.read(path))["entry"]["frontmatter"]
  e.update_columns(frontmatter: e.frontmatter.merge(fm), updated_at: Time.current)
  log << "  entry services/#{slug} <- entries/#{slug}.json (#{fm.keys.size} fields)"
end

Setting.set("general", {"phone" => "(415) 283-6736", "phone_link" => "tel:+14152836736"})
log << "  setting general.phone = (415) 283-6736"

puts "Applied the redesign content to #{base}\n\n"
puts log
puts "\nNext: free-cleanup.rb --apply, then check-site.py."
