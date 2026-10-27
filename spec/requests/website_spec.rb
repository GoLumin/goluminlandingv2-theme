# frozen_string_literal: true

require "rails_helper"

# The theme against the CMS it draws: spec/fixtures/cms/snapshot.json is the
# content model and live content of golumin.io (block types, collections and
# their tag pool, globals and the forms, with their fields, and every live
# page and entry). Every page and entry is drawn from it, so a template that
# reads a field the CMS doesn't declare (Website::Fields) or a form field the
# form doesn't have fails here. Refresh it with bin/rails goluminlandingv2:snapshot.
RSpec.describe "The GoLumin website", type: :request, website: true do
  SNAPSHOT = JSON.parse(Goluminlandingv2::Engine.root.join("spec/fixtures/cms/snapshot.json").read)
  PARTIALS = Goluminlandingv2::Engine.root.glob("app/views/website/blocks/_*.html.erb").map { it.basename.to_s[/\A_(\w+)\./, 1] }
  ENTRY_TEMPLATES = Goluminlandingv2::Engine.root.glob("app/views/website/entries/*.html.erb").map { it.basename.to_s.delete_suffix(".html.erb") }
  ENTRIES = SNAPSHOT["entries"].group_by { it["collection"] }

  before do
    switch_plugin :forms, on: true
    # Another theme linked beside this one (bin/theme link) is switched off, as on a real install.
    Website.themes.each_key { |key| switch_plugin key.to_sym, on: key == "goluminlandingv2" if Cms::Plugins.manifests.key?(key.to_sym) }
    SNAPSHOT["block_types"].each { BlockType.find_or_initialize_by(slug: it["slug"]).update!(it) }
    collections = SNAPSHOT["collections"].to_h { [it["slug"], Collection.create!(it.except("categories_collection", "tags_collection"))] }
    SNAPSHOT["collections"].each do |collection|
      collections[collection["slug"]].update!(categories_collection: collections[collection["categories_collection"]], tags_collection: collections[collection["tags_collection"]])
    end
    SNAPSHOT["globals"].each { |global| Global.find_or_initialize_by(slug: global["slug"]).update!(global.except("fields").merge("schema" => {"fields" => global["fields"]})) }
    SNAPSHOT["forms"].each { Form.create!(it.merge("status" => "published")) }
    SNAPSHOT["pages"].each { |page| Page.find_or_initialize_by(path: page["path"]).update!(page.merge("status" => "published")) }
    SNAPSHOT["entries"].each do |entry|
      collection = collections.fetch(entry["collection"])
      category = entry["category"] && collection.categories_collection.entries.find_by!(slug: entry["category"])
      tags = collection.tags_collection ? collection.tags_collection.entries.where(slug: entry["tags"]).to_a : []
      collection.entries.create!(entry.except("collection", "category", "tags").merge("status" => "published", "category" => category, "tags" => tags))
    end
    Setting.set("general", SNAPSHOT["site"].merge("serving" => "website"))
  end

  def html = Nokogiri::HTML5(response.body)

  def entries(collection) = ENTRIES.fetch(collection).sort_by { it.dig("frontmatter", "order") || 0 }

  SNAPSHOT["pages"].reject { it["path"] == "not-found" }.each do |page|
    path = (page["path"] == "home") ? "/" : "/#{page["path"]}"

    it "draws #{path}, every one of its blocks, with its SEO panel's title and description" do
      get path

      expect(response).to have_http_status(:ok)
      seo = page["seo"].to_h
      expect(html.at_css("title").text).to eq(seo["meta_title"].presence || "#{page["title"]} | GoLumin")
      expect(html.at_css("meta[name=description]")["content"]).to eq(seo["meta_description"]) if seo["meta_description"]
      expect(html.at_css("meta[name=robots]")["content"]).to start_with(seo["noindex"] ? "noindex" : "index")
      page["blocks"].each { expect(PARTIALS).to include(it["type"]) }
      expect(html.css("h1").size).to eq(page["path"] == "thank-you" ? 3 : 1)
      expect(response.body).not_to include("font-mono", "brand-gradient-text") if page["path"] == "home"
    end
  end

  ENTRIES.each do |collection, list|
    drawn = ENTRY_TEMPLATES.include?(collection)

    it "#{drawn ? "draws" : "has no pages for"} every #{collection} entry" do
      list.each do |entry|
        get "/#{collection}/#{entry["slug"]}"

        expect(response).to have_http_status(drawn ? :ok : :not_found), "/#{collection}/#{entry["slug"]}"
        expect(html.at_css("title").text).to eq(entry.dig("seo", "meta_title")) if drawn && entry.dig("seo", "meta_title")
      end
    end
  end

  it "keeps the paid landing pages out of search, and offers their headline variants" do
    entries("lp").each do |lp|
      get "/lp/#{lp["slug"]}"

      expect(html.at_css("meta[name=robots]")["content"]).to start_with("noindex")
      expect(html.at_css("header nav")).to be_nil
      variants = JSON.parse(html.at_css("[data-gl-variants]")["data-gl-variants"])
      expect(variants.keys).to eq(lp.dig("frontmatter", "variants").map { it["key"] })
      expect(html.at_css("[data-lp-h1]").text + html.at_css("[data-lp-h2]").text).to eq(lp.dig("frontmatter", "h").join)
    end
  end

  it "has a partial only for block types the CMS has" do
    expect(PARTIALS - SNAPSHOT["block_types"].map { it["slug"] }).to be_empty
  end

  it "has a partial for every block type an editor can add" do
    expect(SNAPSHOT["block_types"].map { it["slug"] } - PARTIALS).to eq(["pattern"])
  end

  it "draws every block type it has a partial for, from the type's defaults" do
    blocks = SNAPSHOT["block_types"].select { PARTIALS.include?(it["slug"]) }.map { {"type" => it["slug"], "version" => it["version"], "data" => it["defaults"].to_h} }
    Page.new(slug: "every-block", path: "every-block", title: "Every block", status: "published", locale: "en", blocks:).save!(validate: false)

    get "/every-block"

    expect(response).to have_http_status(:ok)
  end

  it "lists the services, case studies and roles in their order, and the posts newest first" do
    get "/services"
    expect(html.css("#services .service-card h3").map(&:text)).to eq(entries("services").map { it.dig("frontmatter", "nav") })

    get "/work"
    expect(html.css("#work a[href^='/work/']").map { it["href"] }.uniq).to eq(entries("work").map { "/work/#{it["slug"]}" })

    get "/careers"
    expect(html.css("main section[id] > .container > .two-col h2.h-2").map(&:text).first(entries("roles").size)).to eq(entries("roles").map { it["title"] })

    get "/blog"
    posts = ENTRIES["blog"].sort_by { it["published_at"].to_s }.reverse
    expect(html.css("main ul a").map { it["href"] }).to eq(posts.map { "/blog/#{it["slug"]}" })
  end

  it "puts every client logo in the band under the hero, each to its case study" do
    get "/"

    with_logo = entries("work").select { it.dig("frontmatter", "logo").present? }
    expect(html.css(".logo-list a").map { it["href"] }.uniq).to eq(with_logo.map { "/work/#{it["slug"]}" })
  end

  it "draws its 404 from the CMS's not-found page, never indexed" do
    get "/no-such-page"

    expect(response).to have_http_status(:not_found)
    expect(html.at_css("h1").text).to include("isn't here")
    expect(html.at_css("meta[name=robots]")["content"]).to start_with("noindex")
  end

  it "takes the nav and footer from their globals, the services and case studies from their collections" do
    get "/"

    nav = SNAPSHOT["globals"].find { it["slug"] == "nav" }["data"]
    expect(html.css("header nav[aria-label=Main] > a, header nav[aria-label=Main] > .nav-item > button").map { it.text.strip }).to eq(nav["items"].map { it["label"] })
    expect(html.css("header nav[aria-label=Main] .nav-panel").first.css(".nav-panel-link").map { it["href"] }).to eq(entries("services").map { "/services/#{it["slug"]}" })
    expect(html.css(".nav-drawer .drawer-group").map { it.css("a").size }).to include(entries("work").size + 1)
    footer = SNAPSHOT["globals"].find { it["slug"] == "footer" }["data"]
    expect(html.css("footer nav .footer-head").map(&:text)).to eq(footer["columns"].map { it["heading"] })
    expect(html.css("footer nav").first.css("a").size).to eq(1 + entries("services").size)
  end

  # A form's fields, posted as a visitor would, with an answer for each.
  def answers(form)
    form.fields.to_h do |field|
      value = if field["options"].present? then field["options"].first["value"]
      else {"email" => "ann@example.com", "tel" => "(269) 555-0123", "url" => "https://example.com"}.fetch(field["type"], "Ann")
      end
      [field["name"], value]
    end
  end

  {"/" => "audit", "/careers" => "application", "/referrals" => "referral", "/blog/what-is-an-ai-agent" => "contact"}.each do |path, slug|
    it "draws the #{slug} form on #{path} from Forms › #{slug}, and posts it to the Forms plugin" do
      get path
      element = html.at_css("form[data-form-slug=#{slug}]")
      names = element.css("input, select, textarea").map { it["name"] } - [Form::HONEYPOT_FIELD]
      form = Form.find_by!(slug:)

      expect(names.uniq).to match_array(form.fields.map { it["name"] })
      expect(element["action"]).to eq("/api/forms/#{slug}/submissions")

      post element["action"], params: answers(form), as: :json
      expect(response).to have_http_status(:created)
      expect(FormSubmission.last.data).to include("email" => "ann@example.com")

      post element["action"], params: answers(form).except("email"), as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  it "routes the audit form: the service's audit preselected, fixed on a landing page, ad spend only when it involves ads" do
    get "/services/websites"
    expect(html.at_css("#audit select[name=audit_type] option[selected]")["value"]).to eq("Website")
    expect(html.at_css("#audit [data-spend-field]")["hidden"]).not_to be_nil

    get "/lp/ads"
    expect(html.at_css("#plan-form input[type=hidden][name=audit_type]")["value"]).to eq("Ad account")
    expect(html.at_css("#plan-form [data-spend-field]")["hidden"]).to be_nil
  end

  it "shows Cloudflare Turnstile on its forms when Settings › Forms has the keys" do
    get "/"
    expect(response.body).not_to include("data-turnstile")

    Setting.set(Forms::SETTING_KEY, {"captcha_provider" => "turnstile", "turnstile_site_key" => "0x4AAA-site", "turnstile_secret_key" => "0x4AAA-secret"})
    get "/"

    expect(html.css("form[data-audit-form] [data-turnstile]").map { it["data-sitekey"] }.uniq).to eq(["0x4AAA-site"])
  end

  it "says thank you for whichever form was sent" do
    get "/thank-you"

    expect(html.css("[data-variant]").map { [it["data-variant"], it["hidden"].nil?] }).to eq([["audit", true], ["referral", false], ["application", false]])
    expect(html.css("[data-variant]").map { it["data-form"] }).to eq(["", "referral", "application"])
  end

  it "designs the forms' emails, filled in per submission" do
    # An email is drawn outside a visit; with another theme linked beside this
    # one (bin/theme link), its templates would come first.
    paths = Website::PagesController.view_paths
    Website::PagesController.prepend_view_path(Goluminlandingv2::Engine.root.join("app/views").to_s)
    form = Form.find_by!(slug: "audit")
    email = form.emails.find_or_initialize_by(kind: "confirmation")
    email.update!(subject: "Thanks, {{name}}", enabled: true, blocks: [
      {"type" => "email_heading", "version" => 1, "data" => {"text" => "Thank you, {{name}}", "level" => "h1"}},
      {"type" => "email_submission", "version" => 1, "data" => {"title" => "What you sent", "skip_empty" => true}}
    ])
    submission = form.submissions.create!(data: {"name" => "Ann", "email" => "ann@example.com", "message" => "Our <b>ads</b>"}, meta: {}, ip: "127.0.0.1")

    mail = FormSubmissionMailer.with(form_email: email, submission:, recipients: ["ann@example.com"]).deliver.message
    body = (mail.html_part || mail).body.decoded

    expect(email.site_template_status).to eq(:theme)
    expect(mail.subject).to eq("Thanks, Ann")
    expect(body).to include("Thank you, Ann", "GoLumin", "&lt;b&gt;ads")
    expect(body.scan("data-cms-repeat").size + body.scan("{{").size).to eq(0)
  ensure
    Website::PagesController.view_paths = paths
  end

  it "follows Customize: the header's phone number, the phone's call and plan bar" do
    get "/"
    expect(html.css("header .nav-phone")).to be_present
    expect(html.at_css("[data-mobile-bar]")).to be_present

    Website::Design.update(Website.theme, {"header_phone" => "0", "sticky_cta" => "0"})
    get "/"
    expect(html.css("header .nav-phone")).to be_empty
    expect(html.at_css("[data-mobile-bar]")).to be_nil
  end

  it "serves its own scripts, stylesheet and fonts, none of the admin's, with nothing compiled" do
    get "/"
    page = html

    importmap = JSON.parse(page.at_css("script[type=importmap]").text)["imports"]
    expect(importmap.keys).to all(start_with("goluminlandingv2"))
    expect(importmap.values).to all(start_with("/_goluminlandingv2/"))
    expect(response.body).not_to include("/assets/application-", "/assets/goluminlandingv2/")

    get page.at_css("link[rel=stylesheet][href^='/_goluminlandingv2/']")["href"]
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/css")
    expect(response.headers["Cache-Control"]).to include("immutable")
    expect(response.body).to include("Inter", ".hero-photo", ".form-card")
    expect(response.body).not_to include("Geist")

    (importmap.values + [page.at_css("[data-mobile-bar]") && page.at_css(".hero-photo i")["style"][/url\(([^)]+)\)/, 1]]).compact.each do |path|
      get path
      expect(response).to have_http_status(:ok), path
    end
    get "/_goluminlandingv2/../../goluminlandingv2.gemspec"
    expect(response).to have_http_status(:not_found)
    get "/_goluminlandingv2/README.md"
    expect(response).to have_http_status(:not_found)
  end
end
