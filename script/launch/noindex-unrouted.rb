# Keeps the sitemap honest. The CMS lists nine collections; the theme has an
# entry template for four of them (app/views/website/entries/). Entries in the
# other five are real records the site uses, but they have no page of their
# own, so every one of them is a sitemap URL that 404s.
#
#   bin/rails runner script/launch/noindex-unrouted.rb [--apply]
#
# The fix is seo.noindex, which drops them from sitemap.xml while leaving the
# records published. Do NOT unpublish them: the client marquee draws published
# `clients`, careers draws `roles`, and the forms draw `team`. Tru-Colors
# Contracting stays a draft, deliberately.
ROUTED = Dir[Rails.root.join("themes/*/app/views/website/entries/*.html.erb")]
  .map { File.basename(it, ".html.erb") }.uniq
abort "No entry templates found; is a theme linked?" if ROUTED.empty?
APPLY = ARGV.include?("--apply")

puts "Routed collections (have an entry template): #{ROUTED.sort.join(", ")}\n\n"
total = 0
Collection.order(:slug).each do |c|
  next if ROUTED.include?(c.slug)

  entries = c.entries.where(status: "published").reject { it.seo.is_a?(Hash) && it.seo["noindex"] }
  next if entries.empty?

  puts "  %-14s %d published entr%s with no page" % [c.slug, entries.size, entries.size == 1 ? "y" : "ies"]
  total += entries.size
  next unless APPLY

  entries.each { it.update_columns(seo: (it.seo || {}).merge("noindex" => true), updated_at: Time.current) }
end
puts "\n#{APPLY ? "Marked" : "Would mark"} #{total} entries noindex. They stay published."
