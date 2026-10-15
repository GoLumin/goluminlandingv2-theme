# frozen_string_literal: true

# The collections, globals, forms, settings and redirects (script/import.rb).
module GoluminImport
  module Content
    module_function

    D = GoluminImport::DATA
    extend GoluminImport

    def run
      settings
      team = people
      clients
      testimonials
      services
      work
      roles
      blog
      landings
      globals(team)
      forms
      redirects
    end

    def settings
      puts "== settings"
      site = D["site"]
      general = Setting.get("general").to_h.merge(
        "title" => "GoLumin",
        "description" => "A full-service marketing agency for local and multi-location businesses: websites, local and AI search, and advertising, run as one system by people you can reach.",
        "phone" => site["phoneLabel"], "email" => site["email"],
        "default_og_image" => asset("/og.png", alt: "GoLumin: more calls, more clients").to_s
      )
      Setting.set("general", general)
      branding = Setting.get("branding").to_h.merge(
        "logo_id" => asset("/logo.png", alt: "Lumin").to_s,
        "favicon_id" => asset("/favicon.svg", alt: "GoLumin").to_s
      )
      Setting.set("branding", branding)
    end

    # The founders, who answer the landing pages' leads (adgroups.ts founders).
    def people
      puts "== team"
      list = snake(D["adgroups"]["founders"]["people"]).each_with_index.map do |p, i|
        p.except("slug").merge("photo" => asset("/team/#{p["slug"]}.webp", alt: p["name"]), "order" => i + 1)
      end
      team = collection("team", name: "Team", icon: "Users",
        fields: fields_for(list, "photo" => {"type" => "asset"}, "name" => {"required" => true}).reject { it["name"] == "name" })
      D["adgroups"]["founders"]["people"].zip(list).each do |raw, p|
        entry(team, raw["slug"], title: p["name"], frontmatter: p.except("name"))
      end
      team
    end

    # Every client in proof.ts; those not cleared for public mention (show: false) as drafts.
    def clients
      puts "== clients"
      list = snake(D["proof"]["clients"]).each_with_index.map { |c, i| c.except("show").merge("order" => i + 1) }
      pool = collection("clients", name: "Clients", icon: "Building2",
        fields: fields_for(list).reject { it["name"] == "name" })
      D["proof"]["clients"].zip(list).each do |raw, c|
        entry(pool, c["name"].parameterize, title: c["name"], frontmatter: c.except("name"), status: raw["show"] ? "published" : "draft")
      end
    end

    # Permissioned client quotes (proof.ts quotes).
    def testimonials
      puts "== testimonials"
      list = snake(D["proof"]["quotes"]).each_with_index.map do |q, i|
        q.except("result", "slug").merge("result_figure" => q.dig("result", "n"), "result_label" => q.dig("result", "l"), "case_study" => q["slug"], "order" => i + 1)
      end
      pool = collection("testimonials", name: "Testimonials", icon: "Quote",
        fields: fields_for(list, "quote" => {"type" => "text"}, "case_study" => {"help" => "The case study's slug (work collection), for the link under the quote."}))
      list.each { |q| entry(pool, q["case_study"].presence || q["name"].parameterize, title: q["name"], frontmatter: q) }
    end

    def services
      puts "== services"
      list = snake(D["services"]["services"]).each_with_index.map do |s, i|
        shot = s.dig("platform", "shot")
        platform = s["platform"].except("shot").merge("image" => (asset("/screens/#{shot["name"]}", alt: shot["alt"]) if shot), "caption" => shot&.dig("cap"))
        s.except("slug", "seo_title", "seo_description", "name").merge("platform" => platform, "order" => i + 1)
      end
      fields = fields_for(list, "platform.image" => {"type" => "asset"},
        "cases" => {"help" => "Case studies (work collection slugs) that evidence this service."},
        "handoff.to" => {"help" => "The next service's slug."},
        "audit.type" => {"help" => "Must be one of the audit form's choices."},
        "chips" => {"label" => "Chips"}, "n" => {"label" => "Number"}, "h" => {"label" => "Page headline"},
        "nav" => {"label" => "Navigation label"}, "card" => {"label" => "Homepage card body"})
      @services = collection("services", name: "Services", icon: "Layers", fields:)
      D["services"]["services"].zip(list).each do |raw, s|
        entry(@services, raw["slug"], title: raw["name"], frontmatter: s, seo: seo(raw["seoTitle"], raw["seoDescription"]))
      end
    end

    # The case studies, with their homepage screenshots and logos.
    LOGO_SIZES = {"mulebox" => [651, 120], "foxbox-moves" => [368, 120], "inbox-portable-storage" => [261, 120],
                  "kalamazoo-mortgage" => [612, 120], "the-foundry" => [200, 120], "wise-insurance" => [283, 120],
                  "white-and-white" => [300, 120], "shine-learning-alliance" => [216, 120]}.freeze

    def work
      puts "== work"
      list = snake(D["work"]["work"]).each_with_index.map do |c, i|
        logo = (asset("/logos/#{c["slug"]}.webp", alt: c["name"]) if LOGO_SIZES.key?(c["slug"]))
        # A table's rows as a repeater of cells: the field DSL has no list of lists.
        c["evidence"] = c["evidence"].map { |e| e["table"] ? e.merge("table" => e["table"].merge("rows" => e["table"]["rows"].map { {"cells" => it} })) : e } if c["evidence"]
        c.except("slug", "seo_description", "name").merge(
          "screenshot" => asset("/work/#{c["slug"]}.webp", alt: "Homepage of #{c["name"]}"), "logo" => logo, "order" => i + 1
        )
      end
      fields = fields_for(list, "screenshot" => {"type" => "asset"}, "logo" => {"type" => "asset", "help" => "The client's mark, for the logo marquee."},
        "h" => {"label" => "Headline"}, "built" => {"label" => "What we built"}, "evidence.table" => {"type" => "group"})
      @work = collection("work", name: "Case studies", icon: "Briefcase", fields:)
      D["work"]["work"].zip(list).each do |raw, c|
        vertical = raw["vertical"].split("·").first.strip
        entry(@work, raw["slug"], title: raw["name"], frontmatter: c, seo: seo("#{raw["name"]}: #{vertical} Case Study | GoLumin", raw["seoDescription"]))
      end
    end

    def roles
      puts "== roles"
      list = snake(D["roles"]["roles"]).each_with_index.map { |r, i| r.except("slug", "title").merge("order" => i + 1) }
      pool = collection("roles", name: "Open roles", icon: "BriefcaseBusiness", fields: fields_for(list, "n" => {"label" => "Number"}))
      D["roles"]["roles"].zip(list).each { |raw, r| entry(pool, raw["slug"], title: raw["title"], frontmatter: r) }
    end

    # ── Posts: MDX into a text block per run of prose and a figure block per <Figure> ──

    FIGURE = %r{<Figure\b(?<attrs>[^>]*)>(?<inner>.*?)</Figure>}m

    def blog
      puts "== blog"
      tags = collection("blog-tags", name: "Blog tags", icon: "Tag", fields: [])
      posts = ASTRO.glob("src/content/blog/*.mdx").sort.map { [it.basename(".mdx").to_s, *parse_mdx(it.read)] }
      fields = [
        {"name" => "eyebrow", "label" => "Kicker", "type" => "string", "help" => "Above the headline, e.g. \"Advertising · ChatGPT Ads\"."},
        {"name" => "lede", "label" => "Standfirst", "type" => "text"},
        {"name" => "description", "label" => "Summary", "type" => "text", "help" => "On the blog index, and the meta description."},
        {"name" => "author", "label" => "Author", "type" => "string"},
        {"name" => "updated_date", "label" => "Updated", "type" => "datetime"},
        {"name" => "service", "label" => "Service", "type" => "string", "help" => "The service (slug) this post sells."},
        {"name" => "og_line", "label" => "Share line", "type" => "string", "help" => "The one sentence the post is about, on its share card."},
        {"name" => "og_scene", "label" => "Share scene", "type" => "select", "options" => %w[agent review shopping]},
        {"name" => "share_image", "label" => "Share image", "type" => "asset", "help" => "The card a link preview shows (headline included)."},
        {"name" => "art", "label" => "Banner art", "type" => "asset", "help" => "The same artwork without the headline, under the title."}
      ]
      # The figure block type first, so the posts' blocks validate against it.
      figures = posts.flat_map { it[2] }.select { it["type"] == "post_figure" }
      block_type("post_figure", label: "Post figure", category: "Media", blocks: figures,
        description: "One of a post's figures (a diagram or a cropped screenshot), with its caption.",
        overrides: {"figure" => {"type" => "select", "options" => %w[thermostat_vs_shift three_kinds surface_area review_timeline atomic_vs_steps insights_gap shot]}})
      blog = collection("blog", name: "Blog", icon: "Newspaper", fields:, blocks: true, tags:)
      posts.each do |slug, meta, blocks, body|
        post_tags = Array(meta["tags"]).map { |t| tags.entries.find_or_create_by!(slug: t.parameterize) { it.assign_attributes(title: t, status: "published", locale: "en") } }
        frontmatter = {
          "eyebrow" => meta["eyebrow"], "lede" => meta["lede"], "description" => meta["description"], "author" => meta["author"] || "GoLumin",
          "updated_date" => meta["updatedDate"]&.to_s, "service" => meta["service"], "og_line" => meta["ogLine"], "og_scene" => meta["ogScene"],
          "share_image" => asset("/blog/#{slug}.png", alt: meta["title"]), "art" => asset("/blog/#{slug}-art.png", alt: "")
        }.compact
        entry(blog, slug, title: meta["title"], frontmatter:, body:, blocks:, tags: post_tags,
          status: meta["draft"] ? "draft" : "published", published_at: Time.zone.parse(meta["pubDate"].to_s),
          seo: seo(meta["seoTitle"], meta["description"]).merge("og_image_id" => frontmatter["share_image"].to_s, "og_type" => "article", "schema_type" => "BlogPosting"))
      end
    end

    # [frontmatter, blocks, markdown body] for a post.
    def parse_mdx(source)
      _, yaml, rest = source.split(/^---\s*$/, 3)
      meta = YAML.safe_load(yaml, permitted_classes: [Date])
      rest = rest.gsub(/^import .*$/, "").gsub(%r{\{/\*.*?\*/\}}m, "")
      blocks = []
      body = []
      position = 0
      rest.to_enum(:scan, FIGURE).map { Regexp.last_match }.each do |match|
        prose = prose(rest[position...match.begin(0)].strip)
        if prose.present?
          blocks << {"type" => "text", "version" => 1, "data" => {"body" => prose}}
          body << prose
        end
        figure = figure_block(match[:attrs], match[:inner])
        blocks << {"type" => "post_figure", "version" => 1, "data" => figure}
        body << "*#{figure["caption"]}*" if figure["caption"].present?
        position = match.end(0)
      end
      tail = prose(rest[position..].to_s.strip)
      if tail.present?
        blocks << {"type" => "text", "version" => 1, "data" => {"body" => tail}}
        body << tail
      end
      [meta, blocks, body.join("\n\n")]
    end

    # Prose as Astro's Markdown set it: a paragraph's wrapped lines joined (the
    # CMS keeps a line break as a <br>), and straight quotes curled, as
    # smartypants did, outside code.
    BLOCK_START = /\A\s*([-*+]\s|\d+\.\s|#|>|\||```|<)/

    def prose(text)
      text.split(/\n{2,}/).map do |para|
        lines = para.split("\n")
        joined = lines.each_with_object([]) do |line, out|
          if out.any? && !line.match?(BLOCK_START) && !out.last.match?(/\A\s*(\||```)/)
            out[-1] = "#{out.last.rstrip} #{line.strip}"
          else
            out << line
          end
        end.join("\n")
        joined.split(/(`[^`]*`)/).map { it.start_with?("`") ? it : curl(it) }.join
      end.join("\n\n")
    end

    def curl(text)
      text.gsub(/(^|[\s(\[—–-])"/, '\1“').gsub('"', "”").gsub(/(^|[\s(\[—–-])'/, '\1‘').gsub("'", "’")
    end

    def figure_block(attrs, inner)
      component = inner[/<(\w+)/, 1]
      data = {"figure" => component.underscore, "caption" => attrs[/cap="([^"]*)"/, 1].to_s, "bare" => attrs.match?(/\bbare\b/)}
      if component == "Shot"
        crop = inner[/crop=\{\{([^}]*)\}\}/, 1].to_s.scan(/(\w):\s*([\d.]+)/).to_h
        data.merge!("image" => asset(inner[/src="([^"]+)"/, 1], alt: inner[/alt="([^"]+)"/, 1]), "host" => inner[/host="([^"]+)"/, 1],
          "crop" => crop.empty? ? "" : %w[x y w h].map { crop[it] }.join(" "))
      elsif component == "SurfaceArea"
        data.merge!("then" => inner[/then=\{(\d+)\}/, 1].to_i, "now" => inner[/now=\{(\d+)\}/, 1].to_i, "now_label" => inner[/nowLabel="([^"]+)"/, 1])
      end
      data
    end

    # ── The paid landing pages (/lp/*): landing.ts's audit pages and adgroups.ts's ad-group pages ──

    def landings
      puts "== landing pages"
      raw = D["landing"]["landings"].map { it.merge("kind" => "service") } + D["adgroups"]["adGroupLandings"].map { it.merge("kind" => "adgroup") }
      list = snake(raw).each_with_index.map do |lp, i|
        variants = lp["variants"].to_h.map { |key, v| {"key" => key, "h" => v["h"], "sub" => v["sub"].to_s} }
        {"show_reviewer" => false, "show_evidence" => false}.merge(lp.except("slug", "seo_title", "seo_description", "variants").merge("variants" => variants, "order" => i + 1))
      end
      fields = fields_for(list,
        "kind" => {"type" => "select", "options" => %w[service adgroup], "help" => "service: one service's audit (the Astro LandingPage); adgroup: one Google Ads ad group, leading with the free landing page."},
        "h" => {"label" => "Headline", "help" => "Two parts; the second is set in the brand gradient."},
        "variants" => {"help" => "Message match: /lp/<slug>?v=<key> swaps the headline (and standfirst)."},
        "cases" => {"help" => "Case studies (work slugs), most relevant first."},
        "service" => {"help" => "The service (slug) this page sells: its problems, platform and FAQs."})
      pool = collection("lp", name: "Landing pages", icon: "Megaphone", fields:)
      raw.zip(list).each do |lp, data|
        entry(pool, lp["slug"], title: lp["eyebrow"], frontmatter: data, seo: seo(lp["seoTitle"], lp["seoDescription"], noindex: true))
      end
    end

    # ── Globals ──

    def globals(team)
      puts "== globals"
      nav_fields = [
        {"name" => "items", "label" => "Items", "type" => "repeater", "of" => [
          {"name" => "label", "label" => "Label", "type" => "string", "required" => true},
          {"name" => "link", "label" => "Link", "type" => "link", "required" => true},
          {"name" => "desktop_menu", "label" => "Hover menu on wide screens", "type" => "boolean"},
          {"name" => "children_from", "label" => "Children from", "type" => "select", "options" => ["", "services", "work"],
           "help" => "List a collection's entries under this item (services or case studies), instead of the children below."},
          {"name" => "children", "label" => "Children", "type" => "repeater", "of" => [
            {"name" => "label", "label" => "Label", "type" => "string"},
            {"name" => "link", "label" => "Link", "type" => "link"},
            {"name" => "note", "label" => "Note", "type" => "string"}
          ]}
        ]},
        {"name" => "cta_label", "label" => "Button label", "type" => "string"},
        {"name" => "cta_link", "label" => "Button link", "type" => "link"}
      ]
      url = ->(v) { {"kind" => "url", "value" => v} }
      global("nav", name: "Navigation", fields: nav_fields, data: {
        "items" => [
          {"label" => "Services", "link" => url.("/services"), "desktop_menu" => true, "children_from" => "services", "children" => []},
          {"label" => "How it works", "link" => url.("/how-it-works"), "desktop_menu" => true, "children_from" => "", "children" => [
            {"label" => "The operating model", "link" => url.("/how-it-works"), "note" => "Agents propose · a person approves"},
            {"label" => "Trust & approvals", "link" => url.("/trust"), "note" => "Access · ownership · guardrails"}
          ]},
          {"label" => "Results", "link" => url.("/work"), "desktop_menu" => false, "children_from" => "work", "children" => []},
          {"label" => "Referrals", "link" => url.("/referrals"), "desktop_menu" => false, "children_from" => "", "children" => []}
        ],
        "cta_label" => "Let's talk", "cta_link" => url.("/lets-talk")
      })

      footer_fields = [
        {"name" => "blurb", "label" => "Under the logo", "type" => "text"},
        {"name" => "columns", "label" => "Columns", "type" => "repeater", "of" => [
          {"name" => "heading", "label" => "Heading", "type" => "string"},
          {"name" => "children_from", "label" => "Then list", "type" => "select", "options" => ["", "services"],
           "help" => "Add a collection's entries after the links below."},
          {"name" => "items", "label" => "Links", "type" => "repeater", "of" => [
            {"name" => "label", "label" => "Label", "type" => "string"},
            {"name" => "link", "label" => "Link", "type" => "link"}
          ]}
        ]},
        {"name" => "copyright", "label" => "Copyright", "type" => "string"},
        {"name" => "tagline", "label" => "Bottom line", "type" => "string"}
      ]
      item = ->(label, value) { {"label" => label, "link" => url.(value)} }
      site = D["site"]
      global("footer", name: "Footer", fields: footer_fields, data: {
        "blurb" => "A full-service marketing agency for local and multi-location businesses: legal, medical, financial and home services alike. Websites, local and AI search, and advertising, run as one system by people you can reach.",
        "columns" => [
          {"heading" => "Services", "children_from" => "services", "items" => [item.("Overview", "/services")]},
          {"heading" => "Company", "children_from" => "", "items" => [
            item.("How Lumin works", "/how-it-works"), item.("Trust & approvals", "/trust"), item.("Results", "/work"),
            item.("Referral program", "/referrals"), item.("Blog", "/blog"), item.("Careers", "/careers"), item.("Let's talk", "/lets-talk")
          ]},
          {"heading" => "Contact", "children_from" => "", "items" => [
            item.(site["phoneLabel"], site["phoneHref"]), item.(site["email"], "mailto:#{site["email"]}"),
            item.("Client sign-in", "https://ads.golumin.io"), item.("Privacy", "/privacy"), item.("Terms", "/terms")
          ]}
        ],
        "copyright" => "GoLumin",
        "tagline" => "Agents propose · a named person approves · software enforces the limits"
      })

      proof = snake(D["proof"])
      global("proof", name: "Proof", data: {
        "metrics_as_of" => proof["metrics_as_of"],
        "metrics" => proof["metrics"].map { |m| {"value" => m["value"]&.to_s.to_s, "prefix" => m["prefix"].to_s, "suffix" => m["suffix"].to_s, "decimals" => m["decimals"].to_i, "label" => m["label"]} }
      }, overrides: {"metrics.value" => {"help" => "A number; blank hides the metric."}, "metrics_as_of" => {"label" => "As of"}})

      ad = snake(D["adgroups"])
      credentials = ad["credentials"].except("badge").merge("badge" => asset(ad["credentials"]["badge"], alt: "Google Partner"))
      global("ad_landing", name: "Ad landing pages", data: {
        "offer" => ad["offer"], "plan" => ad["plan"], "credentials" => credentials,
        "founders" => ad["founders"].except("people"), "reviewer" => ad["reviewer"],
        "benchmarks" => ad["benchmarks"], "click_math" => ad["click_math"], "comparison" => ad["comparison"],
        "faqs" => ad["shared_faqs"]
      }, overrides: {"credentials.badge" => {"type" => "asset"}, "click_math.rows.tone" => {"type" => "select", "options" => %w[muted brand]},
                     "founders" => {"help" => "The people are the team collection."}})

      scripts
    end

    # The tags every page of the Astro site loaded (Base.astro): Google Tag
    # Manager, the Google Ads tag and the OpenAI (ChatGPT Ads) pixel.
    def scripts
      gtm = "GTM-WX6GWCTQ"
      items = [
        {"name" => "Google Tag Manager", "head" => <<~HTML.strip, "body" => %(<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=#{gtm}" height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>)},
          <script>window.dataLayer = window.dataLayer || [];
          (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src='https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);})(window,document,'script','dataLayer','#{gtm}');</script>
        HTML
        {"name" => "Google Ads", "head" => <<~HTML.strip, "body" => ""},
          <script async src="https://www.googletagmanager.com/gtag/js?id=AW-18424158289"></script>
          <script>window.dataLayer = window.dataLayer || []; function gtag(){dataLayer.push(arguments);} gtag('js', new Date()); gtag('config', 'AW-18424158289');</script>
        HTML
        {"name" => "OpenAI (ChatGPT Ads) pixel", "head" => <<~HTML.strip, "body" => ""}
          <script>!function(w,d,s,u){if(w.oaiq)return;var q=function(){q.q.push(arguments)};q.q=[];w.oaiq=q;var j=d.createElement(s);j.async=1;j.src=u;var f=d.getElementsByTagName(s)[0];f.parentNode.insertBefore(j,f)}(window,document,"script","https://bzrcdn.openai.com/sdk/oaiq.min.js");oaiq("init",{pixelId:"9U1HDEyjy9zrNFCtCKTJ2F",debug:true});</script>
        HTML
      ]
      record = Global.find_by!(slug: "scripts")
      record.update!(data: record.data.to_h.merge("items" => items))
    end

    # ── Forms: the four that posted to /api/lead, with the attribution it recorded ──

    ATTRIBUTION = %w[utm_source utm_medium utm_campaign utm_term utm_content gclid fbclid msclkid v landing_path referrer source form_path].freeze

    def forms
      puts "== forms"
      opts = ->(*labels) { labels.map { {"value" => it, "label" => it} } }
      text = ->(name, label, required: false, type: "text", placeholder: nil) { {"name" => name, "label" => label, "type" => type, "required" => required, "placeholder" => placeholder}.compact }
      attribution = ATTRIBUTION.map { {"name" => it, "label" => it.humanize, "type" => "text", "help" => "Filled in by the page (attribution); not shown to visitors."} }
      audit_types = D["services"]["auditTypes"]
      role_titles = D["roles"]["roles"].map { it["title"] }
      definitions = {
        "audit" => {title: "Free audit", submit: "Request my free audit →", fields: [
          {"name" => "audit_type", "label" => "What should we audit?", "type" => "select", "required" => true, "options" => opts.(*audit_types)},
          text.("name", "Name", required: true), text.("email", "Work email", required: true, type: "email"),
          text.("company", "Business", required: true), text.("website_url", "Website", placeholder: "yourbusiness.com"),
          {"name" => "monthly_ad_spend", "label" => "Monthly ad spend", "type" => "select", "help" => "Asked when the audit involves ads.",
           "options" => opts.("Not running ads yet", "Under $2,000", "$2,000 – $10,000", "$10,000 – $50,000", "$50,000+")},
          text.("message", "What's the biggest headache right now?", type: "textarea")
        ]},
        "contact" => {title: "Let's talk", submit: "Send it →", fields: [
          text.("name", "Name", required: true), text.("email", "Work email", required: true, type: "email"),
          text.("company", "Business"), text.("message", "What should we talk about?", required: true, type: "textarea")
        ]},
        "application" => {title: "Application", submit: "Send my application →", fields: [
          {"name" => "role", "label" => "Which role?", "type" => "select", "required" => true, "options" => opts.(*role_titles) + [{"value" => "Something else", "label" => "Something else, I'll explain below"}]},
          text.("name", "Name", required: true), text.("email", "Email", required: true, type: "email"),
          text.("links", "Links", placeholder: "github.com/you, yoursite.com"),
          text.("message", "What have you built or run?", required: true, type: "textarea", placeholder: "One specific thing you owned, and what happened. We would rather read that than a summary of your career.")
        ]},
        "referral" => {title: "Referral", submit: "Register this referral →", fields: [
          {"name" => "referral_type", "label" => "Which is this?", "type" => "select", "required" => true,
           "options" => [{"value" => "Referral", "label" => "I have someone to introduce"}, {"value" => "Join the programme", "label" => "I want to join the programme first"}]},
          text.("name", "Your name", required: true), text.("email", "Your email", required: true, type: "email"), text.("company", "Your business"),
          {"name" => "relationship", "label" => "Where you fit", "type" => "select", "required" => true,
           "options" => opts.("GoLumin client", "Designer or freelancer", "IT provider or MSP", "Accountant, bookkeeper or fractional CFO", "Another agency", "Chamber, franchisor or trade group", "Attorney or healthcare (regulated)", "Something else")},
          text.("referral_company", "Their business"), text.("referral_website", "Their website", placeholder: "theirbusiness.com"),
          text.("referral_contact", "Who we should speak to", placeholder: "Dana Reyes, dana@theirbusiness.com"),
          {"name" => "referral_services", "label" => "What do they need?", "type" => "select",
           "options" => opts.("A website", "Local + AI search", "Advertising", "All three", "Not sure, that's what the audit is for")},
          {"name" => "payout_pref", "label" => "How you'd rather be paid", "type" => "select", "required" => true,
           "options" => opts.("Cash by ACH", "Credit on my own invoice (1.5× the cash value)", "Flat fee, I'm in a regulated profession", "Tell me the options")},
          text.("message", "Anything we should know?", type: "textarea", placeholder: "How you know them, what they've complained about, who else they're talking to. Anything that means we don't waste their first call.")
        ]}
      }
      definitions.each do |slug, d|
        form = Form.find_or_initialize_by(slug: slug)
        form.update!(title: d[:title], status: "published", submit_label: d[:submit], fields: d[:fields] + attribution,
          success_message: "Got it. A named person at GoLumin reads every one, and replies.")
        # The Astro site's lead Function mailed every lead to marketing@ (cc Jordan and Ted).
        form.notification_email&.update!(enabled: true, recipients: "marketing@golumin.io, jordan@golumin.io, ted@golumin.io")
      end
    end

    # public/_redirects, less what the CMS does itself (/sitemap.xml, trailing
    # slashes) and the proposal link (proposals aren't on this site).
    def redirects
      puts "== redirects"
      ASTRO.join("public/_redirects").read.lines.map(&:strip).reject { it.empty? || it.start_with?("#") }.each do |line|
        from, to, code = line.split(/\s+/)
        next if from == "/sitemap.xml" || from.end_with?("/") || from.start_with?("/proposals/")

        Redirect.find_or_initialize_by(source_path: from).update!(destination_url: to, status_code: code.to_i, active: true)
      end
    end
  end
end
