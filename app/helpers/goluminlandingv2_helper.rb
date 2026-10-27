# frozen_string_literal: true

# The theme's own vocabulary on top of WebsiteHelper: the collections as the
# site orders them, its headings with their accented words, its buttons,
# eyebrows and sections, the contact details, and the forms it draws by
# hand. Every helper is gl_ (GoLumin).
module Goluminlandingv2Helper
  INLINE_EDIT_MARKS = [Website::InlineEdit::START, Website::InlineEdit::FINISH, *Website::InlineEdit::DIGITS].join
  GL_DIGESTS = {} # rubocop:disable Style/MutableConstant
  GL_MODULES = %w[site attribution nav motion forms video metrics calc figures].freeze
  # The attribution a form carries (attribution.js fills them from the session).
  ATTRIBUTION = %w[utm_source utm_medium utm_campaign utm_term utm_content gclid fbclid msclkid v landing_path referrer source form_path].freeze

  def gl_name = website_settings["title"].presence || "GoLumin"

  # ── Contact ──

  def gl_phone = website_settings["phone"].presence || "(415) 283-6736"

  def gl_tel(phone = gl_phone) = "tel:+1#{phone.to_s.gsub(/\D/, "").delete_prefix("1")}"

  def gl_email = website_settings["email"].presence || "marketing@golumin.io"

  # ── Collections, in the site's order (their `order` field) ──

  def gl_services = website_entries(:services)

  def gl_work = website_entries(:work)

  def gl_roles = website_entries(:roles)

  def gl_team = website_entries(:team)

  def gl_clients = website_entries(:clients)

  def gl_service(slug) = gl_services.find { it.slug == slug.to_s }

  def gl_case(slug) = gl_work.find { it.slug == slug.to_s }

  # Case studies by slug, in the order given, skipping any that aren't live.
  # A list of work slugs; a comma- or space-separated string works too (a field typed as text).
  def gl_cases(slugs) = (slugs.is_a?(String) ? slugs.split(/[\s,]+/) : Array(slugs)).compact_blank.filter_map { gl_case(it) }

  # A client's permissioned quote: the one for a case study, else the first.
  def gl_testimonial(slug = nil)
    quotes = website_entries(:testimonials)
    slug.present? ? quotes.find { website_fields(it).case_study == slug.to_s } : quotes.first
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # A testimonial by its own slug (a quote block whose attribution names one).
  def gl_testimonial_by_slug(slug)
    website_entries(:testimonials).find { it.slug == slug.to_s }
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Posts, newest first.
  def gl_posts = Collection.find_by!(slug: "blog").entries.then { previewing? ? it : it.live }.sort_by { -(it.published_at || it.created_at).to_f }

  def gl_global(slug) = website_global(slug)

  # ── Words ──

  # A heading with its marked words. The old design had three marks (*brand
  # gradient*, _underline_, ^violet^); this one has a single accent, so every
  # mark sets its words in violet (.em). Plain text otherwise, escaped.
  def gl_heading(text)
    parts = text.to_s.split(/(\*[^*]+\*|_[^_]+_|\^[^^]+\^)/).reject(&:empty?).map do |part|
      part.match?(/\A[*_^](.+)[*_^]\z/m) ? tag.span(part[1..-2], class: "em") : part
    end
    safe_join(parts)
  end

  # A heading's words without their marks, for a title or an alt.
  def gl_plain(text) = text.to_s.gsub(/[*_^]([^*_^]+)[*_^]/, '\1')

  # One line with **bold** words, as a chip or a proof line is written.
  def gl_inline(text)
    safe_join(text.to_s.split(/(\*\*[^*]+\*\*)/).reject(&:empty?).map { |part| part.match?(/\A\*\*.+\*\*\z/m) ? tag.strong(part[2..-3]) : part })
  end

  # "%{count}" in a label, filled in.
  def gl_count(label, count) = label.to_s.gsub("%{count}", count.to_s)

  # A link field as an href, or a string typed as one. In the editor's
  # preview, text carries invisible inline-edit markers: an address is
  # followed, never edited in place.
  def gl_href(link)
    href = link.is_a?(String) ? link : website_href(link)
    href = href.to_s.delete(INLINE_EDIT_MARKS).strip
    href.presence if href.empty? || SafeUrl.safe?(href)
  end

  def gl_external?(href) = href.to_s.match?(%r{\Ahttps?://})

  # ── Pieces ──

  BUTTON_SIZES = {sm: "btn-sm", md: "", lg: "btn-lg"}.freeze
  # The old design's ink, primary, outline and ghost buttons, as this one's:
  # the violet pill, the dark pill, the quiet outlined pill, or an arrowed text link.
  BUTTON_VARIANTS = {ink: "btn btn-primary", primary: "btn btn-primary", dark: "btn btn-dark", outline: "btn btn-ghost", ghost: "btn-link"}.freeze

  # A button: primary (violet), dark, outline or a text link; sm, md or lg.
  # magnet: kept for the templates that pass it; nothing moves any more.
  def gl_button(label, href, variant: :primary, size: :md, cta: nil, magnet: false, **options) # rubocop:disable Lint/UnusedMethodArgument
    variant = {"secondary" => "outline"}.fetch(variant.to_s, variant.to_s).presence&.to_sym
    variant = :primary unless BUTTON_VARIANTS.key?(variant)
    classes = [BUTTON_VARIANTS.fetch(variant), BUTTON_SIZES.fetch(size.to_sym, ""), options.delete(:class)].compact_blank.join(" ")
    label = safe_join([label.to_s.delete_suffix("→").strip, tag.span("→", class: "arrow", aria: {hidden: true})], " ") if variant == :ghost && label.is_a?(String)
    link_to(label, href.to_s, class: classes, data: {cta:}, **options)
  end

  # A block's buttons ({label, link, style}; the core blocks' {label, url, style}).
  def gl_ctas(ctas, size: :md, cta: nil)
    safe_join(Array(ctas).each_with_index.filter_map do |item, index|
      href = gl_href(item.respond_to?(:link) ? item.link : item.url) or next
      gl_button(item.label, href, variant: item.style, size:, cta: cta && "#{cta}-#{index + 1}")
    end)
  end

  # The eyebrow over a section: one quiet violet line, sentence case. The old
  # design's number (n) and brackets are gone; the argument stays for the
  # templates that pass it.
  def gl_eyebrow(text, _n = nil, klass: nil)
    return if text.blank?

    tag.p(text, class: ["eyebrow", klass].compact.join(" "))
  end

  def gl_pulse_eyebrow(text) = gl_eyebrow(text)

  SECTION_TONES = {"bg" => "", "subtle" => "section-alt", "ink" => "section-night"}.freeze

  # A section: white, the soft alternate, or the dark night; a hairline over
  # it (rule); the page width inside. tight: the shorter padding.
  def gl_section(tone: "bg", id: nil, rule: false, klass: nil, tight: false, &block)
    tone = tone.to_s.presence || "bg"
    classes = [(tight ? "section-tight" : "section"), SECTION_TONES.fetch(tone, ""), ("section-line" if rule && tone != "ink"), klass].compact_blank.join(" ")
    tag.section(id: id.presence, class: classes) do
      safe_join([(render("website/shared/scene", key: "night:#{request.path}", night: true) if tone == "ink"), tag.div(class: "container", &block)].compact)
    end
  end

  # The short violet dash that marks a list item.
  def gl_dot(_klass = nil) = tag.span(class: "dash", aria: {hidden: true})

  def gl_check(klass = "check", size: 18)
    tag.svg(tag.path(d: "M20 6 9 17l-5-5"), class: klass, viewBox: "0 0 24 24", width: size, height: size, fill: "none", stroke: "currentColor",
      "stroke-width": "2.2", "stroke-linecap": "round", "stroke-linejoin": "round", aria: {hidden: true})
  end

  PHONE_PATH = "M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.9.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"

  def gl_phone_icon(size = 15, klass: nil)
    tag.svg(tag.path(d: PHONE_PATH), viewBox: "0 0 24 24", width: size, height: size, fill: "none", stroke: "currentColor", "stroke-width": "2",
      "stroke-linecap": "round", "stroke-linejoin": "round", class: klass, aria: {hidden: true})
  end

  # Two-digit numbering: 01, 02…
  def gl_n(index) = format("%02d", index + 1)

  def gl_year = Time.current.year

  # A number as the site writes it: 1,000 / $2,500.
  def gl_money(amount) = "$#{number_with_delimiter(amount.to_f.round)}"

  # ── Images ──

  # An asset as an <img>, or nothing for a blank or missing one.
  def gl_image(id, **options) = website_image_tag(id, **options)

  def gl_image_url(id, width: 1600) = website_image_url(id, width:)

  def gl_logo(**options)
    website_image_tag(Setting.get("branding")["logo_id"], alt: "Lumin", sizes: "6rem", loading: :eager, **options) ||
      image_tag(gl_asset_path("logo.png"), alt: "Lumin", width: 96, height: 38, **options)
  end

  # The branded photographs (the Lumin landscapes, light in the dark) are the
  # theme's own files, brand-1 to brand-10. Every hero is a night hero with one
  # of them behind it, by the page it is on, as the redesign chose them; the
  # dark sections ("night:" keys), the closing call and the client quote have
  # theirs. Anything else gets a steady pick from its key. [number, position]
  BRAND_PHOTOS = {"/" => ["10-hero"], "/home" => ["10-hero"], "/lp" => [1], "/services" => [4], "/services/websites" => [1], "/services/advertising" => [2],
                  "/services/local-ai-search" => [7], "/websites" => [1], "/advertising" => [2], "/search" => [7], "/tracking" => [10], "/work" => [8], "/work/*" => [10],
                  "/how-it-works" => [9], "/how-we-work" => [9], "/trust" => [9], "/about" => [5], "/lets-talk" => [3], "/contact" => [3], "/careers" => [2],
                  "/referrals" => [6], "/blog" => [4], "/blog/*" => [4], "/privacy" => [7], "/terms" => [8], "/thank-you" => [4],
                  "night:/" => [2, "center 30%"], "night:/home" => [2, "center 30%"], "night:/services/advertising" => [7], "night:/advertising" => [7], "night:/how-it-works" => [2, "center 30%"],
                  "night:/how-we-work" => [2, "center 30%"], "closing" => ["9-hero", "60% 70%"], "quote" => [5]}.freeze

  # The photo's url and its position, for a hero (key: the page's path) or a
  # dark section ("night:" + the path), or one named outright ("closing").
  def gl_brand_photo(key)
    key = key.to_s
    prefix, path = key.include?(":") ? key.split(":", 2) : [nil, key]
    path = path.chomp("/").presence || "/"
    path = path.sub(%r{\A/redesign[/-]}, "/") if path.match?(%r{\A/redesign[/-]})
    path = "/lp" if path.start_with?("/lp/")
    lookup = prefix ? "#{prefix}:#{path}" : path
    entry = "/#{path.split("/")[1]}/*" if path.count("/") > 1
    n, position = BRAND_PHOTOS[lookup] || (entry && !prefix && BRAND_PHOTOS[entry]) || BRAND_PHOTOS[[prefix, path.split("/").first(2).join("/")].compact.join(":")] || (prefix == "night" ? [2] : nil) || [Zlib.crc32(path) % 10 + 1]
    [gl_asset_path("brand-#{n}.webp"), position]
  end

  def gl_favicon_href
    id = Setting.get("branding")["favicon_id"].presence
    (id && website_image_url(id, width: 192)) || gl_asset_path("favicon.svg")
  end

  # ── SEO ──

  # The <head>: the SEO panel, with the page's own title as a fallback.
  def gl_seo_tags(record, title: nil, description: nil, image: nil, noindex: false)
    seo = record.respond_to?(:seo) ? record.seo.to_h.stringify_keys : {}
    website_seo_tags(record, title: title || (record&.title && "#{gl_plain(record.title)} | #{gl_name}"), description:,
      image: image || website_settings["default_og_image"].presence, noindex: noindex || website_truthy?(seo["noindex"]))
  end

  # FAQPage structured data for a set of questions.
  def gl_faq_schema(items)
    website_json_ld({"@context" => "https://schema.org", "@type" => "FAQPage", "isPartOf" => {"@id" => "#{website_url("/")}#website"},
                     "mainEntity" => items.map { {"@type" => "Question", "name" => website_plain_text(it.question), "acceptedAnswer" => {"@type" => "Answer", "text" => website_plain_text(it.answer)}} }})
  end

  # ── Forms ──

  def gl_form(slug) = defined?(Form) && Form.find_by(slug: slug.to_s, status: "published")

  # The form's field, by name, held to its definition (website_form_field).
  def gl_field(form, name) = website_form_field(form, name)

  # A select's choices, as the form defines them.
  def gl_choices(field) = defined?(FormChoices) ? FormChoices.for(field) : Array(field["options"])

  # The hidden attribution inputs, for the fields the form declares.
  def gl_attribution(form, source:)
    safe_join(ATTRIBUTION.filter_map do |name|
      next unless form.fields.any? { it["name"] == name }

      value = {"source" => source, "form_path" => request.path}[name].to_s
      tag.input(type: "hidden", name:, value:)
    end)
  end

  # Cloudflare Turnstile's site key when Settings › Forms has it set up (the
  # Forms plugin then refuses a submission without its token), else nil.
  def gl_turnstile_key
    captcha = Forms.public_captcha if defined?(Forms) && Forms.respond_to?(:public_captcha)
    captcha[:site_key] if captcha && captcha[:provider] == "turnstile"
  end

  # A labelled control for one of the form's fields (.field, site.css).
  def gl_control(form, name, id:, label: nil, hint: nil, required: nil, wrapper: nil, rows: 2, select: nil, **attrs)
    field = gl_field(form, name)
    required = field["required"].present? if required.nil?
    label_html = tag.label(for: id, class: "field-label") do
      safe_join([label || field["label"], (tag.span(" #{hint}", class: "hint") if hint)].compact)
    end
    control = case field["type"]
    when "textarea"
      tag.textarea("", id:, name:, rows:, required:, placeholder: attrs.delete(:placeholder) || field["placeholder"], **attrs)
    when "select"
      prompt = select&.dig(:prompt)
      selected = select&.dig(:selected)
      options = gl_choices(field).map { tag.option(it["label"], value: it["value"], selected: it["value"] == selected) }
      options.unshift(tag.option(prompt, value: "", disabled: true, selected: selected.blank?)) if prompt
      tag.select(safe_join(options), id:, name:, required:, **attrs)
    else
      tag.input(type: field["type"].presence_in(%w[email tel url]) || "text", id:, name:, required:, placeholder: attrs.delete(:placeholder) || field["placeholder"], **attrs)
    end
    tag.div(safe_join([label_html, control]), class: ["field", wrapper.presence].compact.join(" "))
  end

  # ── The theme's own files ──

  # A file of the theme's ("site.css", "logo.png") at the address the theme
  # serves it from, with its digest (Goluminlandingv2::AssetsController).
  def gl_asset_path(name)
    file = Goluminlandingv2::AssetsController.find(name) || raise(ArgumentError, "no theme file #{name}")
    digest = (GL_DIGESTS[[name, file.mtime.to_i]] ||= Digest::SHA1.file(file).hexdigest[0, 10])
    "/_goluminlandingv2/#{name}?v=#{digest}"
  end

  # The site's scripts as ES modules from the theme's own files, each
  # preloaded, then the entry point. Instead of website_javascript_tags,
  # which needs the files compiled into the asset pipeline.
  def gl_javascript_tags
    imports = GL_MODULES.to_h { ["goluminlandingv2/#{it}", gl_asset_path("#{it}.js")] }.merge("goluminlandingv2" => gl_asset_path("site.js"))
    nonce = content_security_policy_nonce
    safe_join([
      tag.script(ERB::Util.json_escape({imports:}.to_json).html_safe, type: "importmap", nonce:), # rubocop:disable Rails/OutputSafety -- our own paths, JSON-escaped
      *imports.values.uniq.map { tag.link(rel: "modulepreload", href: it, nonce:) },
      tag.script('import "goluminlandingv2"'.html_safe, type: "module", nonce:) # rubocop:disable Rails/OutputSafety -- a constant
    ], "\n")
  end

  # Whether an href is the page being shown, or one under it.
  def gl_active?(href)
    path = href.to_s.split(/[?#]/).first.to_s.chomp("/")
    current = request.path.chomp("/").presence || "/"
    path.present? && (current == path || (path != "" && current.start_with?("#{path}/")))
  end

  # A section as another page draws it: the first block of a type on a live
  # page (the homepage's human gate, on the ad-account landing page).
  def gl_page_block(path, type)
    block = Array(Page.live.find_by(path: path.to_s)&.expanded_blocks(live: true)).find { it["type"] == type.to_s }
    website_block(block) if block
  end

  # A case study's headline figure: the outcome the client agreed to share,
  # else its first build figure. [figure, label, sub]
  def gl_case_figure(fields)
    if fields.outcome.stat.present?
      [fields.outcome.stat, fields.outcome.label, fields.outcome.sub]
    elsif (f = fields.figures.first)
      [f.n, f.l, nil]
    end
  end

  # A page drawn without the site's nav: the landing pages and the banner page.
  def gl_landing? = content_for?(:landing)
end
