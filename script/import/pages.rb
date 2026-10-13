# frozen_string_literal: true

# The pages and the block types they're composed of (script/import.rb).
# Copy is the Astro pages' and components', as block data; a section the
# Astro site repeats is one block type. Headings mark their highlighted
# words: *brand gradient*, _underline mark_, ^violet^ (Goluminlandingv2Helper#gl_heading).
module GoluminImport
  module Pages
    module_function

    extend GoluminImport
    D = GoluminImport::DATA

    def u(value) = {"kind" => "url", "value" => value}

    def cta(label, href, style = "ink") = {"label" => label, "link" => u(href), "style" => style}

    def b(type, data) = {"type" => type, "data" => data}

    def items(pairs, a = "title", z = "body") = pairs.map { |x, y| {a => x, z => y} }

    def qa(list) = list.map { {"question" => it["q"], "answer" => it["a"]} }

    # ── Shared sections ──

    def audit_form(**overrides)
      b("audit_form", {
        "eyebrow" => "Free audit", "heading" => "Pick the audit you actually need.",
        "blurb" => "Website, local and AI search, ad account, or all three. Read-only access, real findings on your own accounts, and a person who walks you through them. You keep the findings either way.",
        "bullets" => ["Read-only access — nothing changes", "No obligation, no slide deck", "This form is a lead in our own inbox, timer running on us"],
        "audit_type" => D["services"]["auditTypes"].first, "lock_type" => false, "submit_label" => "Request my free audit →",
        "note" => "No obligation. Read-only access.", "prefix" => "footer", "tone" => "subtle"
      }.merge(overrides.transform_keys(&:to_s)))
    end

    def service_cards(**overrides)
      b("service_cards", {
        "eyebrow_n" => "What we do", "eyebrow" => "The offer", "heading" => "Three services. Strongest together.",
        "lede" => "Buy one, or buy the system. Each is a complete service on its own — and each one makes the other two work better, because one team runs all three off the same data.",
        "link_label" => "How they fit together →", "link" => u("/services"), "tone" => "bg"
      }.merge(overrides.transform_keys(&:to_s)))
    end

    def loop_diagram
      b("loop_diagram", {
        "eyebrow_n" => "Why one team", "eyebrow" => "The loop", "heading" => "Leads teach the ads. ^Ads teach the site.^",
        "body" => "Split web, search and ads across three vendors and this loop breaks at every handoff. Nobody sends the sold-lead data back. Nobody rewrites the page the ad points at. One team closes it.",
        "proofs" => items([
          ["Leads teach the ads.", "Mark a lead sold or lost. That verdict goes back to Google and Meta as an offline conversion, so bidding optimises toward customers instead of form fills."],
          ["Pages become ad copy.", "The page that converts becomes the ad. Same promise on both sides of the click, because the same team owns both."],
          ["Ads fix the website.", "A page losing people after the click gets flagged, redrafted by an agent, and sent to an editor to approve."]
        ]),
        "nodes" => [["Search demand", "search"], ["The page", "web"], ["The campaign", "ads"], ["Call or form", "ads"], ["Sold or lost", "you"], ["Next change", "approved"]].map { |l, o| {"label" => l, "owner" => o} },
        "center_title" => "One team", "center_note" => "one person accountable"
      })
    end

    def platforms
      b("platforms", {
        "eyebrow_n" => "Why we're different", "eyebrow" => "The operating system",
        "heading" => "Most agencies rent their tools. *We built ours.*",
        "body" => "Two platforms we wrote and run ourselves. They are how the work gets done faster and gets recorded properly — not a product you have to learn. Most clients never log in.",
        "items" => [
          {"anchor" => "cms", "number" => "01", "name" => "Lumin CMS", "role" => "The web and search layer",
           "heading" => "Publishes your site, and keeps working on it.",
           "body" => "Pages, locations, forms and revisions live in one system of record. A crew of agents each own one job — freshness, internal links, structured data, location pages, metadata — and run it on a schedule. Every edit to a live page is a revision waiting for an editor.",
           "bullets" => ["Edits live in under a minute", "Migrations preserve every URL", "Location data held once, published everywhere", "Agents draft, an editor approves"],
           "image" => asset("/screens/cms-agents.webp", alt: "The website agents in Lumin CMS and the jobs each one runs"),
           "caption" => "The website crew in Lumin CMS. One job each, on a schedule.", "flip" => false},
          {"anchor" => "ads", "number" => "02", "name" => "Lumin Ads", "role" => "The paid media layer",
           "heading" => "Governs the spend, and closes the feedback loop.",
           "body" => "Google, Microsoft, Meta and ChatGPT in one place. Agents mine search terms, pace budget, audit conversion tracking and rewrite tired copy around the clock. Everything they propose lands in a single approvals queue, and sold-lead outcomes go back to the platforms.",
           "bullets" => ["One approvals queue for every channel", "Spend caps enforced at the apply gate", "Sold and lost fed back as offline conversions", "Your accounts, your name, revocable access"],
           "image" => asset("/screens/ads-approvals-board.webp", alt: "The approvals board in Lumin Ads showing proposed changes waiting for a person"),
           "caption" => "The approvals board in Lumin Ads. Nothing applies until a person signs.", "flip" => true}
        ],
        "note_lead" => "You are not buying software.",
        "note" => "Lumin CMS and Lumin Ads are internal operating infrastructure. You buy web, search and advertising as a service; these are what let a small team run them at the pace of a much larger one, and leave a record of every change.",
        "link_label" => "See how it works →", "link" => u("/how-it-works")
      })
    end

    def human_gate
      b("human_gate", {
        "eyebrow_n" => "The human gate", "eyebrow" => "Who signs", "heading" => "Agents do the work. _A person signs for it._",
        "body" => "Nothing consequential reaches a live account or a live page on its own. Four roles, in order, every time.",
        "roles" => [
          ["The agent", "proposes.", "Every change is written up first: what, why, and the evidence — including the money at stake. It has no ability to apply anything."],
          ["A GoLumin operator", "approves.", "A named person signs or rejects. Never their own work. Their name stays on the record next to the change."],
          ["The software", "enforces.", "Spend caps are hard limits at the apply gate. A change over the cap cannot apply, even after a human approves it."],
          ["You", "can stop it.", "One switch pauses every agent on your account, instantly, without a support ticket or a phone call."]
        ].map { |w, t, d| {"who" => w, "title" => t, "body" => d} },
        "link_label" => "What never runs on its own →", "link" => u("/trust"),
        "caption" => "The approvals queue in Lumin Ads, running on a demo account."
      })
    end

    def operating_proof
      b("operating_proof", {
        "eyebrow" => "Operating proof · verifiable, not asserted",
        "heading" => "The strongest proof isn't that we use AI. It's *the record of what changed, who approved it, and what happened next.*",
        "stats" => [
          ["<1 min", "Approved edit to live page", "A property of the CMS, not a service-level promise. The publish is the deploy."],
          ["0", "Changes applied without a named approver", "Agents have no apply permission. Every consequential change carries a person's name."],
          ["Hard", "Spend caps, enforced in code", "A proposal over the cap is blocked at the apply gate — even when a human has approved it."]
        ].map { |v, l, d| {"value" => v, "label" => l, "body" => d} },
        "body" => "Outcome numbers — leads, cost per qualified lead, revenue — belong to a client and a timeframe, so we publish them on the case study that can carry the baseline and the method, not in a headline.",
        "link_label" => "%{count} client sites live today →", "link" => u("/work")
      })
    end

    def case_studies(**overrides)
      b("case_studies", {
        "eyebrow_n" => "Results", "eyebrow" => "Live right now", "heading" => "Sites we built. Running today.",
        "body" => "Every figure below comes from the live site or its sitemap at capture time. Where a client's performance data is theirs to release, we ask first and publish the baseline and the method with it.",
        "cases" => [], "all" => false, "link_label" => "All %{count} case studies →", "tone" => "subtle", "note_lead" => "", "note" => ""
      }.merge(overrides.transform_keys(&:to_s)))
    end

    def engagement
      b("engagement", {
        "eyebrow_n" => "What to expect", "eyebrow" => "The first two weeks", "heading" => "No mystery about ^what happens next.^",
        "phases" => [
          {"when" => "Days 1–3", "title" => "Audit", "body" => "Read-only access to the accounts and the site. The agents go through them and a person writes up the findings.",
           "items" => ["Read-only, nothing changes", "You keep the findings, hired or not", "A person walks you through it"]},
          {"when" => "Days 4–10", "title" => "Onboard", "body" => "Accounts connected, tracking verified, caps and approval rules set with you before a single agent runs.",
           "items" => ["Your accounts stay in your name", "You set the spend caps", "Conversion tracking audited first"]},
          {"when" => "Day 10 onward", "title" => "Operate", "body" => "Agents run on their schedules. Proposals land in the queue, a named person approves, changes apply and get recorded.",
           "items" => ["Proposals with evidence attached", "One plain-English email each week", "Leads on your phone as they arrive"]}
        ],
        "answers" => [
          ["What access do you need?", "Read-only on your ad accounts and analytics to start. Write access only after onboarding, and only for what you have agreed to."],
          ["Who owns the accounts?", "You do, throughout. Ad accounts, domain, content and phone numbers stay in your name. Our access is revocable."],
          ["What do I get each week?", "One email in plain English: what was proposed, what was approved, what changed, and what it did. No dashboard homework."],
          ["How do I stop something?", "Reject the proposal, lower the cap, or hit the pause switch. Any of those, at any time, with no notice period on the button."]
        ].map { |q, a| {"question" => q, "answer" => a} }
      })
    end

    def faq(list, heading:, eyebrow: "Questions", tone: "bg")
      b("faq", {"eyebrow" => eyebrow, "heading" => heading, "items" => list, "tone" => tone})
    end

    HOME_FAQS = [
      ["Are you an agency or a software company?", "An agency. You buy websites, local and AI search, and advertising as a service. Lumin CMS and Lumin Ads are the software we built to deliver them; you never have to touch either."],
      ["Can I buy just one service?", "Yes. Plenty of clients start with ads, or with a site. The three are strongest together because the loop closes, but none of them is a condition of the others."],
      ["Can the AI change my ads or my site on its own?", "No. Every consequential change waits for a named person at GoLumin. Spend caps are hard limits in software and cannot be overridden, even by an approver."],
      ["Do I keep my accounts and my content?", "Yes. Ad accounts, domain, content and phone numbers stay in your name. Access is revocable and the content is portable."],
      ["Do I need to be technical?", "No. One plain-English email a week and leads on your phone. Most clients never log into either platform."],
      ["How is it priced?", "A monthly fee based on ad spend and whether we run your site. Quoted after the free audit, once we know what is actually there."]
    ].map { |q, a| {"question" => q, "answer" => a} }.freeze

    def page_hero(eyebrow:, heading:, lede:, chips: [], ctas: [], crumb: nil, items_style: "none", items: [])
      data = {"eyebrow" => eyebrow, "heading" => heading, "lede" => lede, "chips" => chips, "ctas" => ctas, "items_style" => items_style, "items" => items}
      data.merge!("crumb_label" => crumb[0], "crumb_link" => u(crumb[1])) if crumb
      b("page_hero", data)
    end

    def numbered(eyebrow_n:, eyebrow:, heading:, items:, body: nil, tone: "subtle", size: "md", quoted: false, marker: "number", ctas: [], anchor: nil)
      b("numbered_list", {"eyebrow_n" => eyebrow_n, "eyebrow" => eyebrow, "heading" => heading, "body" => body.to_s, "items" => items,
                          "tone" => tone, "heading_size" => size, "quoted" => quoted, "marker" => marker, "ctas" => ctas, "anchor" => anchor.to_s})
    end

    # ── The pages ──

    def run
      puts "== pages"
      @all = {}
      add "home", "Home", seo("Full-Service Marketing Agency — Web, Search & Ads | GoLumin",
        "Marketing agency for local and multi-location businesses. We build websites, win local and AI search, and run your ads as one system. Get a free audit."), home
      add "services", "Services", seo("Marketing Services: Web, Local + AI Search & Ads | GoLumin",
        "Three marketing services run as one system: websites, local and AI search, and paid advertising. See what each includes and request a free audit."), services_page
      add "how-it-works", "How it works", seo("How It Works: AI Agents Propose, People Approve | GoLumin",
        "How GoLumin works: AI agents propose the changes, a named person approves them, and software enforces the spend caps. See the operating model."), how_it_works
      add "trust", "Trust & approvals", seo("Trust: Account Access, Approvals & Ownership | GoLumin",
        "How GoLumin handles account access, approvals and ownership. Your ad accounts, domain and content stay yours, and nothing consequential runs unapproved."), trust
      add "work", "Results", seo("Client Results & Marketing Case Studies | GoLumin",
        "Marketing case studies: websites we built and the local businesses we run search and ads for. Real pages, real quote flows, real figures."), work_index
      add "blog", "Blog", seo("Blog: Paid Media, Local & AI Search Notes | GoLumin",
        "Notes from running websites, local and AI search, and advertising on our own platforms. What actually changed, and what it means for the accounts we run."), blog_index
      add "careers", "Careers", seo("Careers: Marketing & Engineering Jobs | GoLumin",
        "Open marketing and engineering roles at GoLumin — Google Ads, Meta Ads, local and AI search, and full-stack engineering. See the openings and apply."), careers
      add "lets-talk", "Let's talk", seo("Contact GoLumin: Request a Free Marketing Audit",
        "Call (269) 532-6248 or send the form. A named person at GoLumin reads every enquiry — read-only access, real findings on your own accounts, and no obligation."), lets_talk
      add "referrals", "Referrals", seo("Referral Program: Earn 10% for 12 Months | GoLumin",
        "Refer a business to GoLumin and earn 10% of everything they pay us for their first 12 months: websites, local and AI search, and advertising. No cap, no tiers."), referrals
      add "privacy", "Privacy", seo("Privacy Policy | GoLumin", "How GoLumin handles information submitted on this page.", noindex: true), privacy
      add "terms", "Terms", seo("Terms of Service | GoLumin", "Terms for using this page.", noindex: true), terms
      add "thank-you", "Thanks", seo("Thanks · GoLumin", "Thanks for getting in touch with GoLumin.", noindex: true), thank_you
      add "not-found", "Page not found", seo("Page not found | GoLumin",
        "That page doesn't exist. Find GoLumin's services, results and contact details here.", noindex: true), not_found
      add "laspalmas", "Las Palmas Jog-A-Thon", seo("Lumin at the Las Palmas Jog-A-Thon | Free Marketing Plan",
        "Lumin sponsors the Las Palmas Elementary Jog-A-Thon in San Clemente. Websites, digital advertising and AI for local businesses — plus a free marketing plan you keep.").merge(
          "og_image_id" => asset("/laspalmas-banner.jpg", alt: "The Lumin banner at the Las Palmas Elementary Jog-A-Thon").to_s), laspalmas
      block_types
      @all.each { |path, (title, seo, blocks)| page(path, title:, seo:, blocks:) }
    end

    def add(path, title, seo, blocks) = (@all[path] = [title, seo, blocks])

    def home
      metrics_note = "Running now for"
      [
        b("home_hero", {
          "eyebrow" => "GoLumin", "badge_label" => "We're hiring", "badge_link" => u("/careers"),
          "heading" => "More calls. *More clients.*",
          "lede" => "Web, search and ads, run as one growth system — for local and multi-location businesses.",
          "body" => "Law firms, medical and dental practices, mortgage and insurance, home services, storage and moving. We connect your site, your local and AI visibility and your paid media, through software we built and people you can reach.",
          "video_title" => "GoLumin in 44 seconds", "video_duration" => "0:44",
          "video_base" => "https://media.golumin.io/video", "video_name" => "golumin-promo-v2",
          "video_label" => "A 44-second tour of GoLumin: AI agents that propose changes to your ads, search and website, and the people who approve them.",
          "ctas" => [cta("Request a free audit", "#hero-audit"), cta("Careers", "/careers", "outline")],
          "chips" => ["Web + CMS", "Local + AI search", "Ads"],
          "featured_label" => metrics_note, "featured_clients" => ["Inbox Portable Storage", "White & White Construction", "Robinson Law"],
          "audit_eyebrow" => "Free audit", "audit_heading" => "Real findings. Your accounts.",
          "audit_body" => "Read-only access. The agents look, a person walks you through it. You keep the findings either way.",
          "audit_type" => D["services"]["auditTypes"].first, "testimonial" => "behnke-logistics"
        }),
        b("client_logos", {"label" => "Running now for", "linked" => true}),
        service_cards,
        loop_diagram,
        platforms,
        human_gate,
        operating_proof,
        case_studies,
        engagement,
        faq(HOME_FAQS, heading: "Asked on every first call."),
        audit_form
      ]
    end

    def services_page
      [
        page_hero(eyebrow: "Services · the full system", heading: "Everything a local business needs to *turn local demand into customers.*",
          lede: "Three services, one team, one feedback loop. Buy the one you need now; the others make it work harder when you are ready.",
          chips: ["Websites", "Local + AI search", "Google", "Meta", "Microsoft", "ChatGPT"],
          ctas: [cta("Request a free audit", "#audit"), cta("See how we deliver it", "/how-it-works", "outline")]),
        service_cards(tone: "subtle", heading: "Three services. One repeatable way of working.",
          lede: "Each one stands alone. Each one hands something to the next. Below each card is the page that shows the work in detail."),
        numbered(eyebrow_n: "The outcome", eyebrow: "What you're buying", heading: "Three services. ^One promise.^", tone: "bg",
          body: "More qualified demand, captured and improved as one system — rather than pages, listings, campaigns, forms and calls living in separate agency silos that never speak to one another.",
          items: items([
            ["More qualified demand", "Not more traffic and not more form fills. The leads your team would actually want to call back."],
            ["One team accountable", "From the search someone makes to the lead your phone rings with. No handoff for a problem to fall through."],
            ["A record of every change", "What was proposed, who approved it, when it applied and what it did. Available to you, not just to us."]
          ])),
        loop_diagram,
        b("cards", {"eyebrow_n" => "Packaging", "eyebrow" => "How to start", "heading" => "Start anywhere. _Strongest together._", "body" => "",
                    "columns" => "3", "tone" => "bg", "numbered" => false, "service_links" => true,
                    "items" => [
                      {"kicker" => "Common", "title" => "Buy one service", "body" => "Ads only, or a website only, is a normal way to start. Most engagements do."},
                      {"kicker" => "Better", "title" => "Buy two", "body" => "Web and search together, since the same pages do both jobs. Or ads and web, so the landing page and the campaign match."},
                      {"kicker" => "Strongest", "title" => "Buy the system", "body" => "All three, so the loop closes: sold leads teach the ads, the ads teach the site, the site feeds search."}
                    ]}),
        engagement,
        faq([
          ["Can I buy the services separately?", "Yes. Web, local and AI search, and advertising are each a complete service. The recommended engagement is all three, because that is the only shape where the feedback loop actually closes — but it is a recommendation, not a requirement."],
          ["Who is this for?", "Local and multi-location businesses where a phone call or a form is the sale: law firms, medical and dental practices, mortgage and insurance, home services and trades, storage and moving. The channel mix differs by category; the operating model does not."],
          ["Who is it not for?", "Ecommerce catalogues, app installs, and anyone who wants a vendor to execute a plan they have already written. We take accountability for the outcome, which means having opinions about the plan."],
          ["Do I have to use your CMS?", "Only if we build or run the site. We manage ads for plenty of businesses whose sites live somewhere else."],
          ["How is it priced?", "A monthly fee based on ad spend and whether we run your site. Quoted after the free audit, once we have seen what is actually there."]
        ].map { |q, a| {"question" => q, "answer" => a} }, heading: "What buyers ask before the first call."),
        audit_form
      ]
    end

    def how_it_works
      [
        page_hero(eyebrow: "How Lumin works · the operating model", heading: "Agents propose. *People approve.* Software enforces the limits.",
          lede: "We are an agency, not a software vendor. But the reason a small team can run your web, search and ads together — and show you a record of every change — is that we wrote the software we run them with.",
          chips: ["Lumin CMS", "Lumin Ads", "Scheduled agents", "Human approvals", "Hard caps"],
          ctas: [cta("Request a free audit", "#audit"), cta("Read the trust page", "/trust", "outline")]),
        numbered(eyebrow_n: "The model", eyebrow: "What you're hiring", heading: "Four things that make ^this different.^", items: items([
          ["A small team, not a pod", "You get named people, not an account-manager layer in front of the people doing the work. The person who approves a change is someone you can email."],
          ["Agents on schedules", "Each agent has one job — mine search terms, pace budget, audit tracking, flag stale pages — and a shift it runs on. They inspect and propose; they cannot apply."],
          ["One approvals queue", "Web changes and ad changes land in the same place, with the evidence attached. That is why the two sides of your marketing stay in step."],
          ["A record that outlives us", "Every applied change carries what, why, who approved it and when. If you leave, the accounts, the content and the history are yours."]
        ])),
        platforms,
        human_gate,
        b("steps", {"eyebrow_n" => "Worked example", "eyebrow" => "One email", "heading" => "Email at 9:14. ^Approved at 9:31.^",
                    "aside" => "What the gate looks like from your side: no ticket queue, no Tuesday meeting. An agent reads the live account, a person decides.",
                    "columns" => "3", "figures" => true, "tone" => "bg", "anchor" => "story",
                    "items" => [
                      {"kicker" => "9:14", "title" => "You", "body" => "“We're still getting calls about the $300/day ad. Can we fix it?”"},
                      {"kicker" => "9:15", "title" => "Agent", "body" => "Reads the live account. Finds the price extension. Drafts the removal."},
                      {"kicker" => "9:31", "title" => "Person", "body" => "Checks it, approves it. Applied. You get a reply, not a ticket."}
                    ],
                    "note" => "An illustration of the approval path, not a response-time guarantee. Turnaround depends on the change and who has to sign it."}),
        b("client_portal", {"eyebrow_n" => "What you see", "eyebrow" => "Your app", "heading" => "Leads on your phone ^in seconds.^",
                            "body" => "Your own app, in your brand. Push notification, tap to call, speed-to-lead measured. One plain-English email every Friday. No dashboards."}),
        operating_proof,
        faq([
          ["What exactly can an agent do without a human?", "Read. Agents have read access to your accounts and content, and no apply permission. They can inspect, research, draft and propose. Applying anything consequential requires a named approver, and the spend caps are enforced separately at the apply gate."],
          ["Which model runs the agents?", "The agents are driven through Claude and local harnesses. Which model runs a given job is an implementation detail we change when a better one ships; the approval gate and the caps do not change with it."],
          ["What happens if an agent proposes something bad?", "It gets rejected, and the rejection is part of the record. A proposal that exceeds a hard cap never reaches an approver's judgement at all — it is blocked at the apply gate."],
          ["Can I see the queue?", "Yes. Clients who want visibility get access to the approvals history for their own account. Most prefer the weekly email, so that is the default."],
          ["Do I have to learn your software?", "No. Most clients never log in. The deliverable is the marketing, not the tool."]
        ].map { |q, a| {"question" => q, "answer" => a} }, heading: "What people ask about the agents."),
        audit_form
      ]
    end

    def trust
      g = D["guardrails"]
      [
        page_hero(eyebrow: "Trust · approvals, access and ownership", heading: "What we *can* do, what we _can't_, and who signs.",
          lede: "Handing an agency access to your ad accounts and your website is a real risk, and 'we have human oversight' is not an answer. Here is the mechanism, in plain English.",
          chips: ["Read-only to start", "Named approvers", "Hard caps", "Your accounts", "One-switch pause"],
          ctas: [cta("Request a free audit", "#audit"), cta("See the operating model", "/how-it-works", "outline")]),
        b("trust_lists", {"eyebrow_n" => "The line", "eyebrow" => "Where autonomy stops", "heading" => "An agent can look and propose. _It cannot act._",
                          "never_label" => "Never without a person", "never" => g["never"],
                          "always_label" => "Runs on a schedule, unsupervised", "always" => g["always"],
                          "note" => "The right-hand column is all reads and drafts. Nothing on it touches a live account or a live page."}),
        b("definitions", {"eyebrow_n" => "The detail", "eyebrow" => "Eight questions", "heading" => "The answers we'd want ^if it were our account.^", "body" => "",
                          "style" => "ruled", "tone" => "bg", "items" => [
                            ["Account ownership", "Your Google, Microsoft, Meta and ChatGPT ad accounts stay in your name, with you as owner. We are granted access, and you can revoke it from your own account settings without losing a day of history. Same for the domain, the phone numbers, and the content."],
                            ["Data access", "We ask for read-only access to start, on the ad accounts and analytics. Write access comes only after onboarding, and only for what you have agreed to. We do not need, and do not ask for, access to your CRM billing, payroll, or customer records beyond the lead data you route to us."],
                            ["Model use", "The agents are driven through Claude and local harnesses. Your account data is used to do your work — inspect, research, draft — and is not sold, shared with other clients, or used to train a third-party model. Which model runs a given job is an implementation detail; the approval gate does not change with it."],
                            ["Human approvals", "Every consequential change is approved by a named person at GoLumin before it applies. Approvers do not approve their own proposals. The name, the timestamp and the agent's original reasoning stay attached to the change."],
                            ["Spend limits", "Caps are enforced at the apply gate, in code, not by policy. A proposal over the per-change cap is blocked and shown to you as blocked — an approval does not override it. You set the caps during onboarding and can lower them at any time."],
                            ["Audit history", "Applied changes, rejected proposals and blocked ones all stay on the record, with the evidence that was attached at the time. Clients who want to see the queue get access to their own account's history."],
                            ["Pause and offboarding", "One switch pauses every agent on your account, instantly, without a support ticket. If you leave, the ad accounts are already yours, the content is portable, and the URLs are yours. We do not hold anything hostage as leverage on a renewal."],
                            ["Retention", "We keep lead and change records for as long as you are a client and for a reasonable period afterwards so the history stays intact. Ask and we will delete what is ours to delete. See the privacy page for the formal version."]
                          ].map { |t, d| {"term" => t, "body" => d} }}),
        numbered(eyebrow_n: "Claim discipline", eyebrow: "How we use numbers", heading: "Every number on this site ^has a label.^",
          body: "Marketing numbers are easy to write and hard to check. So each one we publish is one of three kinds, with the timeframe, the sample and the method attached. Where we cannot support a number, we describe the mechanism instead and let you judge it.",
          items: items([
            ["Portfolio result", "Aggregated across clients we run. Always carries the sample and the window."],
            ["Representative client result", "One named client, one timeframe, with the baseline and where the number came from."],
            ["Operating benchmark", "A property of how the platform runs — publish time, cap enforcement, change frequency — verifiable in the product."]
          ])),
        b("callout", {"heading" => "Something here not answered?", "body" => "Email a person. We would rather answer an awkward question before you sign than after.",
                      "button_label" => "Email marketing@golumin.io", "button_link" => u("mailto:marketing@golumin.io"),
                      "footnote" => "The formal versions: [privacy policy](/privacy) and [terms](/terms)."}),
        audit_form
      ]
    end

    def work_index
      [
        page_hero(eyebrow: "Case studies", heading: "Different industries. Different problems. *Every number counted,* not claimed.",
          lede: "A selection from our client work, one case study each: what the business needed, what we built, and the numbers as they stand on the live site today. Every figure is counted from the sitemap or the pages at capture, not from a deck."),
        case_studies(eyebrow_n: "", eyebrow: "", heading: "", body: "", all: true, link_label: "",
          note_lead: "On the numbers.",
          note: "What you see here is build evidence — what exists, at what scale, on a live site we are responsible for. Client performance data belongs to the client, so we publish it only where they have agreed, and with the baseline, the timeframe and the method attached."),
        audit_form
      ]
    end

    def blog_index
      [
        page_hero(eyebrow: "Blog · %{count}", heading: "Notes from *inside the accounts.*",
          lede: "What we've learned running client accounts on platforms we wrote ourselves. Written when something actually changes, not on a content calendar."),
        b("post_list", {"empty" => "Nothing published yet."})
      ]
    end

    def careers
      [
        page_hero(eyebrow: "Careers · 4 open roles · remote, US", heading: "Come build the agency that *runs on software it wrote.*",
          lede: "We're a marketing agency that wrote its own ads platform and its own CMS, and runs both with AI agents that a person signs for. It's a small team, early, with the room that implies.",
          chips: ["Remote (US)", "Early team", "Full-time"],
          ctas: [cta("Apply now", "#apply"), cta("See how we work", "/how-it-works", "outline")], items_style: "roles"),
        b("cards", {"eyebrow_n" => "How we work", "eyebrow" => "Before the roles", "heading" => "A startup, said out loud.",
                    "body" => "Small team, real clients, real money moving through accounts we're accountable for. That's the appeal and it's also the warning. Four things we actually select for:",
                    "columns" => "2", "tone" => "subtle", "numbered" => true, "service_links" => false,
                    "items" => snake(D["roles"]["values"]).map { {"kicker" => "", "title" => it["t"], "body" => it["d"]} }}),
        b("roles", {"apply_label" => "Apply for this role", "apply_link" => u("#apply"), "location" => "Remote, US"}),
        b("steps", {"eyebrow_n" => "", "eyebrow" => "Hiring process · four steps, no surprises", "heading" => "We'll give you an answer *either way.*", "aside" => "",
                    "columns" => "4", "figures" => false, "tone" => "ink", "anchor" => "",
                    "items" => D["roles"]["process"].each_with_index.map { |s, i| {"kicker" => format("%02d", i + 1), "title" => s["t"], "body" => s["d"]} },
                    "note" => "On pay: we'd rather talk about it openly against what you'd actually own than post a band we'd outgrow in a year. Bring your number to the first call and we'll be straight with you."}),
        b("form_section", {"form" => "application", "eyebrow_n" => "Apply", "eyebrow" => "Start here", "heading" => "Tell us about ^one thing you built.^",
                           "body" => "Not your whole career — one specific thing you owned and what happened to it. That tells us more than a résumé does, and it's what we'll want to talk about anyway.",
                           "bullets" => ["A person reads every application", "Links beat attachments — GitHub, a site you run, an account you turned around", "No role that fits? Say so in the message and pick 'Something else'"],
                           "footnote" => "Prefer email with a CV attached? [marketing@golumin.io](mailto:marketing@golumin.io)", "anchor" => "apply", "tone" => "subtle"})
      ]
    end

    def lets_talk
      site = D["site"]
      [
        page_hero(eyebrow: "Contact", heading: "Let's *talk.*",
          lede: "Call and you get a person. Send the form and a person reads it. Either way you end up talking to someone who can actually answer the question, not to a sequence."),
        b("contact_cards", {"eyebrow_n" => "Two ways in", "eyebrow" => "Pick whichever suits", "items" => [
          {"kicker" => "Call us", "title" => site["phoneLabel"], "body" => "The fastest route. Useful when you would rather describe the problem out loud than type it into a box.", "link_label" => "Tap to call →", "link" => u(site["phoneHref"])},
          {"kicker" => "Email us", "title" => site["email"], "body" => "Best if you want to attach something — an account screenshot, a proposal from someone else, a list of what hurts.", "link_label" => "Open your mail app →", "link" => u("mailto:#{site["email"]}")}
        ]}),
        audit_form(heading: "Or have us look first.",
          blurb: "Tell us what to audit and we will go through it before we talk, so the conversation starts with findings from your own accounts rather than with questions. Read-only access. No obligation."),
        b("steps", {"eyebrow_n" => "After you send it", "eyebrow" => "What happens next", "heading" => "", "aside" => "", "columns" => "3", "figures" => false, "tone" => "bg", "anchor" => "",
                    "items" => [
                      ["A person reads it", "A named person at GoLumin, not an autoresponder and not a sequence. If you called, you already spoke to one."],
                      ["Read-only access", "We ask for read-only access to whatever you want looked at. Nothing changes, and nothing can — the access we ask for cannot write."],
                      ["Real findings", "The agents go through it, a person writes it up, and we walk you through what they found. You keep the findings either way."]
                    ].each_with_index.map { |(t, d), i| {"kicker" => format("%02d", i + 1), "title" => t, "body" => d} }, "note" => ""})
      ]
    end

    def referrals
      r = snake(D["referrals"])
      t = r["terms"]
      [
        page_hero(eyebrow: "Referrals · #{t["rate"]}% for #{t["months"]} months · no cap", heading: "The best leads we get are *introductions.* So we pay for them.",
          lede: "You already tell people who to use. This is the version where you get paid for it. One rate across every service, paid monthly on money we actually collect, for a full year.",
          chips: ["One rate", "Paid on collected revenue", "Cash or credit", "No tiers to unlock"],
          ctas: [cta("Register a referral", "#refer"), cta("See what it pays", "#worth", "outline")], items_style: "figures",
          items: [["#{t["rate"]}%", "of everything they pay us"], ["#{t["months"]} mo", "from their first paid invoice"],
                  ["#{t["credit_multiple"]}×", "if you take credit instead of cash"], ["No cap", "the first pays like the tenth"]].map { |n, l| {"kicker" => "", "title" => n, "note" => l} }),
        b("cards", {"eyebrow_n" => "", "eyebrow" => "The deal · one sentence, no asterisk", "heading" => r["headline"],
                    "body" => "Not #{t["rate"]}% of the website and something else on the retainer. Not a tier you unlock after three. One number, every service, every invoice, for a year, because a deal you cannot repeat from memory over coffee is a deal nobody repeats.",
                    "columns" => "3", "tone" => "ink", "numbered" => true, "service_links" => false, "items" => [
                      {"kicker" => "", "title" => "Websites, search, ads, same rate", "body" => "Build, migration, hosting, local and AI search, ad management. If they pay us for it, you earn on it."},
                      {"kicker" => "", "title" => "Paid on what clears, not what we bill", "body" => "#{t["payout_days"]} days after their money reaches us, with the invoice attached so you can check the arithmetic."},
                      {"kicker" => "", "title" => "Cash, or #{t["credit_multiple"]}× as credit", "body" => "ACH to whoever the W-9 names. If you are a client, take it as credit instead and it is worth half again as much."}
                    ]}),
        b("referral_calc", {"eyebrow_n" => "What it pays", "eyebrow" => "Your numbers", "heading" => "Move the sliders. ^That's the cheque.^",
                            "body" => "Put in what you think the business you have in mind actually spends. One referred client is usually worth more than a month of whatever you are being paid to think about this.",
                            "rate" => t["rate"], "months" => t["months"], "credit_multiple" => t["credit_multiple"].to_s, "payout_days" => t["payout_days"],
                            "build" => r["calc"]["build"], "monthly" => r["calc"]["monthly"], "anchor" => "worth",
                            "note" => "Your numbers, not ours. We quote after the audit, so there is no price list to paste in here. Commission is calculated on what the client pays GoLumin and never on ad spend passed through to Google or Meta."}),
        numbered(eyebrow_n: "Who refers", eyebrow: "The people who send them", heading: "You are probably already doing this for free.", tone: "bg", size: "md", marker: "tag",
          body: "Nobody on this list set out to be a marketing salesperson. They are just the person who gets asked the question, because they are already trusted with something adjacent.",
          ctas: [cta("Register a referral", "#refer")],
          items: r["who"].map { {"title" => it["t"], "tag" => it["line"], "body" => it["d"]} }),
        b("steps", {"eyebrow_n" => "How it runs", "eyebrow" => "Four steps", "heading" => "Make the intro. ^That's your part.^", "aside" => "", "columns" => "4", "figures" => false,
                    "tone" => "subtle", "anchor" => "", "note" => "",
                    "items" => r["steps"].each_with_index.map { |s, i| {"kicker" => format("%02d", i + 1), "title" => s["t"], "body" => s["d"]} }}),
        numbered(eyebrow_n: "Your name", eyebrow: "What happens to them", heading: "A referral spends your credibility, not ours.", tone: "bg", marker: "dot",
          body: "The reason people stop referring is not the money. It is the one time they sent a friend somewhere and had to hear about it afterwards. So here is exactly what the person you introduce walks into.",
          ctas: [cta("How the work runs", "/how-it-works", "outline"), cta("Read the case studies", "/work", "ghost")],
          items: items([
            ["A free audit, and they keep it", "Read-only access to what they already have. Real findings, written down, theirs whether or not they hire us."],
            ["A person on the phone, not a deck", "Someone who has read their account walks them through it. No pitch built before we looked."],
            ["No pressure, and no pipeline games", "If we are not the right fit we say so on that call. We would rather lose one introduction than the next nine."],
            ["You hear back either way", "Signed, stalled or passed, from us, not from you having to ask them how it went."],
            ["They never find out what you earned", "The commission is between you and us. Nothing on their invoice mentions it unless you want it to."]
          ])),
        b("definitions", {"eyebrow_n" => "The rules", "eyebrow" => "Before you ask", "heading" => "The small print, ^printed large.^",
                          "body" => "Every line here is an argument somebody has had with a referral programme before. Better to settle them on a page you can re-read than in an email six months in.",
                          "style" => "bottom", "tone" => "subtle", "items" => r["rules"].map { {"term" => it["t"], "body" => it["d"]} }}),
        b("split_callout", {"eyebrow_n" => "Regulated", "eyebrow" => "Legal and healthcare", "heading" => "If you're an attorney or a provider, a percentage is the wrong instrument.",
                            "body" => "We work with law firms and with clinics, so this comes up. Percentage-of-revenue referral fees paid to attorneys are governed by state bar rules, and arrangements involving healthcare providers can implicate the federal Anti-Kickback Statute. Those are real constraints, not paperwork, and we are not going to quietly hand you a number that creates a problem for your licence.",
                            "callout_label" => "What we offer instead",
                            "callout_body" => "A flat fee at fair market value for a defined service, not a share of what the referred client spends, in a written agreement your compliance counsel reviews before anyone signs. Ask on the form and we will send the paper rather than a rate.",
                            "footnote" => "None of this is legal advice, and we are not your counsel. Run any arrangement past your own before you enter it."}),
        faq(qa(r["faqs"]), heading: "Asked before the first introduction.", tone: "subtle"),
        b("form_section", {"form" => "referral", "eyebrow_n" => "Refer", "eyebrow" => "Start here", "heading" => "Who do you ^have in mind?^",
                           "body" => "Give us a business name and someone to speak to. It is registered to you the moment this lands, and you will hear from a person within one business day.",
                           "bullets" => ["Registered to you for #{t["window"]} days from the introduction", "We tell you within a day if they were already talking to us",
                                         "No contract to sign before you refer, the terms above are the terms", "Not ready to name anyone? Pick the second option and we'll just send the details"],
                           "footnote" => "", "anchor" => "refer", "tone" => "bg"})
      ]
    end

    def privacy
      [b("legal", {"heading" => "Privacy", "updated" => "Last updated 9 September 2026", "body" => <<~MD})]
        This page is operated by GoLumin (Martin Business Consultants), a marketing agency that builds and runs Lumin Ads and Lumin CMS. It exists to let you request a free audit.

        ## What we collect

        When you submit the audit form we store the name, email address, business, website, ad spend range and message you enter, together with campaign attribution such as UTM parameters and ad click identifiers, the page you landed on, and the referring site. This lands in our own Lumin lead inbox and is used to reply to you and to measure which campaigns bring demo requests.

        ## Analytics and advertising tags

        The page may load Google Tag Manager, Google Analytics, Google Ads conversion tracking and the Meta pixel. These set cookies and report page views and conversions to those providers under their own privacy policies. You can block them with your browser settings or an ad blocker; the form still works.

        ## What we do not do

        We do not sell your information. We do not add you to an automated email sequence. A person replies.

        ## Retention and your rights

        Demo requests are kept while we work with you or for up to 24 months, whichever is longer. Email [marketing@golumin.io](mailto:marketing@golumin.io) to ask what we hold about you, to correct it, or to have it deleted.
      MD
    end

    def terms
      source = ASTRO.join("src/pages/terms.astro").read
      paragraphs = source.scan(%r{<(p|h2)[^>]*>(.*?)</\1>}m).map do |tag, html|
        text = html.gsub(%r{<a [^>]*href="([^"]+)"[^>]*>(.*?)</a>}m, '[\2](\1)').gsub(/<[^>]+>/, "").squish
        (tag == "h2") ? "## #{text}" : text
      end
      updated = paragraphs.find { it.start_with?("Last updated") }
      [b("legal", {"heading" => source[%r{<h1[^>]*>(.*?)</h1>}m, 1].to_s.strip, "updated" => updated.to_s, "body" => (paragraphs - [updated]).join("\n\n")})]
    end

    def thank_you
      [
        ["audit", "", "Request received · timer running on us", "Got it. *We're on it.*", "Your request is now a lead in our own inbox, with the same speed-to-lead timer we put on our clients running on us.", [
          ["Reply", "A named person at GoLumin reads your request and replies. Not an autoresponder and not a sequence."],
          ["Access", "We ask for read-only access to whatever you asked us to audit. Nothing changes, and nothing can."],
          ["Findings", "The agents look, a person writes it up, and we walk you through it. You keep the findings either way."]
        ], "Audit requested"],
        ["referral", "referral", "Referral registered · timestamped to you", "Got it. *That one's yours.*", "It's registered against your name from this moment. A person replies within one business day, including if it turns out they were already talking to us.", [
          ["Registered", "Logged with today's date and attributed to you. Nothing about the introduction depends on you chasing us."],
          ["We reach out", "The same free audit anyone gets: read-only access, findings they keep either way, and no pitch built before we looked."],
          ["You hear back", "Signed, stalled or passed, from us. If they sign, the first payment follows 30 days after their money clears."]
        ], "Referral registered"],
        ["application", "application", "Application received · a person reads every one", "Got it. *We're reading it.*", "No screener, no keyword filter. Someone on the team reads what you wrote and you get an answer either way.", [
          ["Read", "A person reads every application, including the ones that don't fit. Links get opened."],
          ["Reply", "You hear back either way. A no is a no you actually receive, not silence you have to interpret."],
          ["Talk", "If it's a fit, a call about the one thing you told us you built. Not a panel and not a puzzle."]
        ], "Application received"]
      ].map do |key, form, eyebrow, heading, lede, steps, title|
        b("confirmation", {"variant" => key, "form" => form, "title" => title, "eyebrow" => eyebrow, "heading" => heading, "lede" => lede,
                           "steps" => items(steps), "back_label" => "← Back to the page", "back_link" => u("/")})
      end
    end

    def not_found
      [b("error_page", {
        "eyebrow" => "Error 404 · page not found", "heading" => "That page *isn't here.*",
        "lede" => "The link may be old, or the address mistyped. Everything we do is one of the three services below — or say hello and we'll point you at the right thing.",
        "ctas" => [cta("Back to the homepage", "/"), cta("Let's talk", "/lets-talk", "outline")],
        "elsewhere_label" => "Elsewhere",
        "elsewhere" => [["Services", "/services", "Websites, local and AI search, advertising."], ["Results", "/work", "Sites we built and the businesses we run them for."],
                        ["How Lumin works", "/how-it-works", "Agents propose, people approve, software enforces."], ["Let's talk", "/lets-talk", "A free audit, and a named person who replies."]]
          .map { |l, h, d| {"label" => l, "link" => u(h), "body" => d} }
      })]
    end

    def laspalmas
      lp = snake(D["laspalmas"])
      banner = lp["banner"]
      [
        b("qr_hero", {
          "offer_link_label" => "What's included →", "eyebrow" => lp["hero"]["eyebrow"], "wordmark" => banner["wordmark"],
          "heading" => "#{banner["line"][0]}*#{banner["line"][1]}*", "sub" => lp["hero"]["sub"], "platforms" => banner["platforms"],
          "checks" => lp["hero"]["checks"], "submit_label" => lp["hero"]["submit_label"], "phone_label" => banner["phone_label"], "phone_link" => u(banner["phone_href"]),
          "form_heading" => "Tell us about your business.", "note" => "No obligation. The plan is yours to keep.",
          "sponsor_line" => "Proud sponsor of the #{lp["school"]["name"]} #{lp["school"]["event"]}."
        }),
        b("banner_story", {
          "eyebrow_n" => "01", "eyebrow" => "The banner", "heading" => "#{lp["why"]["h"][0]}*#{lp["why"]["h"][1]}*", "body" => lp["why"]["body"],
          "image" => asset(banner["image"]["src"], alt: "The Lumin banner at the #{lp["school"]["name"]} #{lp["school"]["event"]}: #{banner["wordmark"]}. #{banner["line"].join}"),
          "caption" => "The banner · #{lp["school"]["place"]}", "funds_label" => "What the sponsorship funds", "funds" => lp["school"]["funds"],
          "funds_note" => "The #{lp["school"]["name"]} PTA's own list, from its [Jog-A-Thon sponsorship page](#{lp["school"]["pta_url"]}). Lumin is a sponsor, not a partner of the school or the PTA, and neither has reviewed this page."
        }),
        b("pain_grid", {"eyebrow_n" => "02", "eyebrow" => "Where most of it goes wrong", "heading" => "#{lp["pains"]["h"][0]}*#{lp["pains"]["h"][1]}*",
                        "items" => lp["pains"]["items"].map { {"title" => it["t"], "body" => it["d"]} }}),
        b("plan_offer", {"eyebrow_n" => "03", "eyebrow" => "What you walk away with", "offer_label" => "And if you do hire us"}),
        b("click_math", {"eyebrow_n" => "04", "eyebrow" => "Why the page matters more than the budget", "heading" => "Same %{clicks} clicks. *Very different months.*",
                         "body" => "Advertising buys you a click. What happens in the next eight seconds is a separate problem, and it is the one almost nobody solves. Here is the same traffic landing in three different places."}),
        b("proof_cases", {"eyebrow_n" => "05", "eyebrow" => "Proof, with the numbers attached", "heading" => "Businesses about the size of yours. *Here is what changed.*",
                          "body" => "Every figure below is the client's own data, published with their sign-off, with the baseline and the timeframe attached. None of it is rounded in our favour.",
                          "cases" => lp["cases"]}),
        b("client_wall", {"eyebrow_n" => "06", "eyebrow" => "Who we run this for", "heading" => "Local service businesses, mostly. *Same problems as yours.*"}),
        b("comparison", {"eyebrow_n" => "07", "eyebrow" => "How we are different", "heading" => "The things that only matter *once you have signed.*", "us_label" => "Lumin"}),
        b("founders", {"eyebrow_n" => "08", "eyebrow" => "Who picks up"}),
        faq(qa(lp["faqs"]), heading: "The things people ask on the field."),
        b("closing_form", {"heading" => "#{lp["closing"]["h"][0]}*#{lp["closing"]["h"][1]}*", "blurb" => lp["closing"]["blurb"],
                           "phone_kicker" => "The number on the banner", "phone_label" => banner["phone_label"], "phone_link" => u(banner["phone_href"]),
                           "submit_label" => lp["hero"]["submit_label"], "note" => "No obligation. The plan is yours to keep."})
      ]
    end

    # ── Block types: one per section, its fields from the blocks above ──

    TYPES = {
      "home_hero" => ["Home hero", "Sections", "The homepage's opening: the promise, the 44-second video, the proof line and the audit form under it."],
      "page_hero" => ["Page hero", "Sections", "A page's opening on the engineering-paper grid: eyebrow, headline, standfirst, chips, buttons and an optional ruled row."],
      "client_logos" => ["Client logos", "Sections", "The marquee of client marks, each to its case study (the work collection's logos)."],
      "service_cards" => ["Service cards", "Sections", "The three services as cards (the services collection)."],
      "numbered_list" => ["Numbered list", "Sections", "A heading on the left, a ruled numbered list on the right."],
      "loop_diagram" => ["Loop diagram", "Sections", "The feedback loop: six stages round a circle, with the three proofs beside it."],
      "platforms" => ["Platforms", "Sections", "Lumin CMS and Lumin Ads, each with its screenshot."],
      "human_gate" => ["Human gate", "Sections", "The four roles beside the approvals-queue illustration."],
      "operating_proof" => ["Operating proof", "Sections", "The dark band of operating figures. %{count} in the link is the number of case studies."],
      "case_studies" => ["Case studies", "Sections", "Case-study cards from the work collection: the slugs listed, else the first four, or all of them."],
      "engagement" => ["Engagement", "Sections", "The first two weeks, phase by phase, and the four answers under them."],
      "faq" => ["FAQ", "Sections", "Questions that open in place, with FAQPage structured data."],
      "audit_form" => ["Audit form", "Forms", "The free-audit section: the pitch on the left, the audit form (Forms › audit) on the right."],
      "cards" => ["Cards", "Sections", "Bordered cards in two or three columns; optionally the service links under them."],
      "steps" => ["Steps", "Sections", "A ruled row of numbered steps."],
      "client_portal" => ["Client app", "Sections", "The leads app on a phone, beside its copy."],
      "trust_lists" => ["Never / always", "Sections", "What never happens without a person, and what runs on its own."],
      "definitions" => ["Definitions", "Sections", "Terms and their answers, in two columns."],
      "callout" => ["Callout", "Sections", "A bordered box with a heading and a button, and a line under it."],
      "contact_cards" => ["Contact cards", "Sections", "Large linked cards: call us, email us."],
      "roles" => ["Open roles", "Sections", "Every open role (the roles collection), in full."],
      "form_section" => ["Form section", "Forms", "A form (application or referral) beside its pitch."],
      "referral_calc" => ["Referral calculator", "Sections", "Two sliders and what a referral pays."],
      "split_callout" => ["Split callout", "Sections", "A heading beside body copy and a highlighted callout."],
      "confirmation" => ["Confirmation", "Sections", "One thank-you variant; the page shows the one for the form that was sent."],
      "error_page" => ["Not found", "Sections", "The 404: headline, the services and the rest of the site."],
      "post_list" => ["Post list", "Content", "Every published post, newest first."],
      "legal" => ["Legal text", "Content", "A policy: heading, date and Markdown."],
      "post_figure" => ["Post figure", "Media", "One of a post's figures (a diagram or a cropped screenshot), with its caption."],
      "qr_hero" => ["QR landing hero", "Sections", "The banner page's opening: the offer bar, the banner's line and the plan form."],
      "banner_story" => ["Banner story", "Sections", "Why we're on the banner, the photo and what the sponsorship funds."],
      "pain_grid" => ["Pain grid", "Sections", "Four problems, in a ruled grid."],
      "plan_offer" => ["Plan and offer", "Sections", "The free marketing plan and the free landing page (the Ad landing pages global)."],
      "click_math" => ["Click maths", "Sections", "The same clicks landing in three places (the Ad landing pages global). %{clicks} is their number."],
      "proof_cases" => ["Proof cases", "Sections", "The case studies listed, the first in full."],
      "client_wall" => ["Client wall", "Sections", "Every published client and what we did for them (the clients collection)."],
      "comparison" => ["Comparison", "Sections", "Most agencies against us (the Ad landing pages global)."],
      "founders" => ["Founders", "Sections", "The team collection, with the Ad landing pages global's heading."],
      "closing_form" => ["Closing form", "Forms", "The dark closing section: the banner's phone number and the plan form."]
    }.freeze

    def block_types
      puts "== block types"
      blocks = @all.values.flat_map(&:last)
      post_blocks = CollectionEntry.joins(:collection).where(collections: {slug: "blog"}).flat_map { Array(it.blocks) }
      overrides = {
        "tone" => {"type" => "select", "options" => %w[bg subtle ink]},
        "heading_size" => {"type" => "select", "options" => %w[md lg]},
        "marker" => {"type" => "select", "options" => %w[number dot tag]},
        "items_style" => {"type" => "select", "options" => %w[none capabilities roles figures]},
        "columns" => {"type" => "select", "options" => %w[2 3 4]},
        "style" => {"type" => "select", "options" => %w[ruled bottom]},
        "ctas.style" => {"type" => "select", "options" => %w[ink primary outline ghost]},
        "audit_type" => {"type" => "select", "options" => D["services"]["auditTypes"]},
        "form" => {"type" => "select", "options" => ["", "application", "referral", "contact"]},
        "variant" => {"type" => "select", "options" => %w[audit referral application]},
        "figure" => {"type" => "select", "options" => %w[thermostat_vs_shift three_kinds surface_area review_timeline atomic_vs_steps insights_gap shot]},
        "cases" => {"help" => "Case studies (work collection slugs)."},
        "heading" => {"help" => "Mark words *for the brand gradient*, _for the underline_ or ^in violet^."}
      }
      TYPES.each do |slug, (label, category, description)|
        used = (slug == "post_figure") ? post_blocks.select { it["type"] == slug } : blocks.select { it["type"] == slug }
        raise "no block uses #{slug}" if used.empty?

        type_overrides = overrides.dup
        type_overrides["body"] = {"type" => "markdown"} if slug == "legal"
        block_type(slug, label:, category:, description:, blocks: used, overrides: type_overrides.reject { |_, v| v.compact.empty? })
      end
    end
  end
end
