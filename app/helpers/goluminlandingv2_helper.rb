# frozen_string_literal: true

# The theme's own vocabulary on top of WebsiteHelper: the collections as the
# Astro site ordered them, its headings with their highlighted words, its
# buttons, eyebrows and sections, the contact details, and the forms it
# draws by hand. Every helper is gl_ (GoLumin).
module Goluminlandingv2Helper
  INLINE_EDIT_MARKS = [Website::InlineEdit::START, Website::InlineEdit::FINISH, *Website::InlineEdit::DIGITS].join
  GL_DIGESTS = {} # rubocop:disable Style/MutableConstant
  GL_MODULES = %w[site attribution motion forms video metrics calc figures].freeze
  # The attribution a form carries (lead-forms.js fills them from the session).
  ATTRIBUTION = %w[utm_source utm_medium utm_campaign utm_term utm_content gclid fbclid msclkid v landing_path referrer source form_path].freeze

  def gl_name = website_settings["title"].presence || "GoLumin"

  # ── Contact ──

  def gl_phone = website_settings["phone"].presence || "(269) 532-6248"

  def gl_tel(phone = gl_phone) = "tel:+1#{phone.to_s.gsub(/\D/, "").delete_prefix("1")}"

  def gl_email = website_settings["email"].presence || "marketing@golumin.io"

  # ── Collections, in the Astro site's order (their `order` field) ──

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

  # Posts, newest first.
  def gl_posts = Collection.find_by!(slug: "blog").entries.then { previewing? ? it : it.live }.sort_by { -(it.published_at || it.created_at).to_f }

  def gl_global(slug) = website_global(slug)

  # ── Words ──

  # A heading with its marked words: *brand gradient*, _underline mark_,
  # ^violet^. Plain text otherwise, escaped.
  def gl_heading(text)
    parts = text.to_s.split(/(\*[^*]+\*|_[^_]+_|\^[^^]+\^)/).reject(&:empty?).map do |part|
      case part
      when /\A\*(.+)\*\z/m then tag.span($1, class: "brand-gradient-text")
      when /\A_(.+)_\z/m then tag.span($1, class: "mark")
      when /\A\^(.+)\^\z/m then tag.span($1, class: "text-primary")
      else part
      end
    end
    safe_join(parts)
  end

  # A heading's words without their marks, for a title or an alt.
  def gl_plain(text) = text.to_s.gsub(/[*_^]([^*_^]+)[*_^]/, '\1')

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

  BUTTON_BASE = "inline-flex items-center justify-center gap-2 font-semibold rounded-md transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary whitespace-nowrap"
  BUTTON_SIZES = {md: "h-11 px-5 text-[15px]", lg: "h-14 px-7 text-base"}.freeze
  BUTTON_VARIANTS = {
    ink: "bg-text text-bg hover:bg-primary",
    primary: "bg-primary text-on-primary hover:bg-primary-strong",
    outline: "bg-transparent text-text border-2 border-text hover:bg-text hover:text-bg",
    ghost: "text-text underline decoration-2 underline-offset-[6px] decoration-signal hover:decoration-text"
  }.freeze

  # A button (ui/Button.astro): ink, primary, outline or ghost; md or lg.
  # magnet: wrapped in the magnetic zone, as the page's primary action is.
  def gl_button(label, href, variant: :ink, size: :md, cta: nil, magnet: false, **options)
    variant = {"secondary" => "outline"}.fetch(variant.to_s, variant.to_s).presence&.to_sym
    classes = [BUTTON_BASE, BUTTON_SIZES.fetch(size.to_sym), BUTTON_VARIANTS.fetch(variant || :ink, BUTTON_VARIANTS[:ink]), ("magnet" if magnet), options.delete(:class)].compact.join(" ")
    button = link_to(label, href.to_s, class: classes, data: {cta:}, **options)
    magnet ? tag.span(button, class: "magnet-zone") : button
  end

  # A block's buttons ({label, link, style}; the core blocks' {label, url,
  # style}), the first magnetic and large.
  def gl_ctas(ctas, size: :lg, cta: nil)
    safe_join(Array(ctas).each_with_index.filter_map do |item, index|
      href = gl_href(item.respond_to?(:link) ? item.link : item.url) or next
      gl_button(item.label, href, variant: item.style, size:, magnet: index.zero? && item.style.to_s.in?(["", "ink", "primary"]), cta: cta && "#{cta}-#{index + 1}")
    end)
  end

  # The bracketed eyebrow over a section (ui/Eyebrow.astro).
  def gl_eyebrow(text, n = nil, klass: nil)
    return if text.blank? && n.blank?

    tag.p(class: "mb-5 flex items-center gap-3 font-mono text-[12px] uppercase tracking-[0.18em] text-text #{klass}") do
      safe_join([(tag.span(n, class: "tag") if n.present?), tag.span(class: "h-2 w-2 shrink-0 bg-signal", aria: {hidden: true}), text].compact)
    end
  end

  # The pulsing eyebrow of a dark (console) band.
  def gl_pulse_eyebrow(text)
    tag.p(class: "reveal mb-6 flex items-center gap-3 font-mono text-[12px] uppercase tracking-[0.18em] text-text-subtle") do
      safe_join([tag.span(class: "pulse-dot relative inline-block h-1.5 w-1.5 rounded-full bg-signal"), text])
    end
  end

  SECTION_TONES = {"bg" => "", "subtle" => "bg-bg-subtle", "ink" => "console ink"}.freeze

  # A section (ui/Section.astro): its tone, the 2px rule over it, the page width.
  def gl_section(tone: "bg", id: nil, rule: true, klass: nil, &block)
    classes = [SECTION_TONES.fetch(tone.to_s.presence || "bg", ""), ("rule-t" if rule), "py-16 md:py-24", klass].compact_blank.join(" ")
    tag.section(id: id.presence, class: classes) { tag.div(class: "mx-auto w-full max-w-6xl px-5 md:px-8", &block) }
  end

  # The signal-blue square that marks a list item.
  def gl_dot(klass = "mt-[7px] h-2 w-2") = tag.span(class: "#{klass} shrink-0 bg-signal", aria: {hidden: true})

  def gl_check(klass = "mt-[3px] shrink-0 text-primary", size: 18)
    tag.svg(tag.path(d: "M20 6 9 17l-5-5"), class: klass, viewBox: "0 0 24 24", width: size, height: size, fill: "none", stroke: "currentColor",
      "stroke-width": "3", "stroke-linecap": "round", "stroke-linejoin": "round", aria: {hidden: true})
  end

  PHONE_PATH = "M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.9.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92z"

  def gl_phone_icon(size = 15, klass: nil)
    tag.svg(tag.path(d: PHONE_PATH), viewBox: "0 0 24 24", width: size, height: size, fill: "none", stroke: "currentColor", "stroke-width": "2",
      "stroke-linecap": "round", "stroke-linejoin": "round", class: klass, aria: {hidden: true})
  end

  # Two-digit numbering: 01, 02…
  def gl_n(index) = format("%02d", index + 1)

  def gl_year = Time.current.year

  # A number as the Astro site wrote it: 1,000 / $2,500.
  def gl_money(amount) = "$#{number_with_delimiter(amount.to_f.round)}"

  # ── Images ──

  # An asset as an <img>, or nothing for a blank or missing one.
  def gl_image(id, **options) = website_image_tag(id, **options)

  def gl_image_url(id, width: 1600) = website_image_url(id, width:)

  def gl_logo(**options)
    website_image_tag(Setting.get("branding")["logo_id"], alt: "Lumin", sizes: "8rem", loading: :eager, **options) ||
      image_tag(gl_asset_path("logo.png"), alt: "Lumin", width: 100, height: 40, **options)
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

  # FAQPage structured data for a set of questions (Faq.astro).
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

  INPUT = "h-11 w-full rounded-md border-2 border-border bg-bg px-3 text-[15px] outline-none transition-colors focus:border-text"
  TEXTAREA = "w-full rounded-md border-2 border-border bg-bg px-3 py-2.5 text-[15px] outline-none transition-colors focus:border-text"

  # A labelled control for one of the form's fields, styled as the Astro forms were.
  def gl_control(form, name, id:, label: nil, hint: nil, required: nil, wrapper: nil, rows: 2, select: nil, **attrs)
    field = gl_field(form, name)
    required = field["required"].present? if required.nil?
    label_html = tag.label(for: id, class: "mb-1.5 block text-sm font-medium") do
      safe_join([label || field["label"], (tag.span(" #{hint}", class: "font-normal text-text-muted") if hint)].compact)
    end
    control = case field["type"]
    when "textarea"
      tag.textarea("", id:, name:, rows:, required:, placeholder: field["placeholder"], class: TEXTAREA, **attrs)
    when "select"
      prompt = select&.dig(:prompt)
      selected = select&.dig(:selected)
      options = gl_choices(field).map { tag.option(it["label"], value: it["value"], selected: it["value"] == selected) }
      options.unshift(tag.option(prompt, value: "", disabled: true, selected: selected.blank?)) if prompt
      tag.select(safe_join(options), id:, name:, required:, class: INPUT, **attrs)
    else
      tag.input(type: field["type"].presence_in(%w[email tel url]) || "text", id:, name:, required:, placeholder: field["placeholder"], class: INPUT, **attrs)
    end
    tag.div(safe_join([label_html, control]), class: wrapper.presence)
  end

  # ── The theme's own files ──

  # A file of the theme's ("site.css", "logo.png") at the address the theme
  # serves it from, with its digest (Goluminlandingv2::AssetsController).
  def gl_asset_path(name)
    digest = (GL_DIGESTS[name] ||= Digest::SHA1.file(Goluminlandingv2::AssetsController.find(name) || raise(ArgumentError, "no theme file #{name}")).hexdigest[0, 10])
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

  # A page drawn without the site's nav: the landing pages and the banner page.
  def gl_landing? = content_for?(:landing)
end
