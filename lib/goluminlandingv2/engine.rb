# frozen_string_literal: true

module Goluminlandingv2
  # A theme is an engine like a plugin: its views and helpers join the app's,
  # and it registers with Website, which turns the public site on. Its scripts
  # get an importmap of their own (config/importmap.rb), so the admin's never
  # reach a visitor.
  class Engine < ::Rails::Engine
    initializer "goluminlandingv2.importmap", before: "importmap" do |app|
      app.config.assets.paths << root.join("app/javascript")
    end

    # The theme's files, served by the theme (Goluminlandingv2::AssetsController),
    # ahead of the website's catch-all.
    initializer "goluminlandingv2.routes" do |app|
      app.routes.append do
        get "_goluminlandingv2/*path", to: "goluminlandingv2/assets#show", format: false, as: :goluminlandingv2_asset
      end
    end

    config.to_prepare do
      # A plugin too, so Settings › Plugins installs it from its GitHub
      # release, updates it, and switches the site on and off.
      Cms::Plugins.register :goluminlandingv2, name: "GoLumin", version: Goluminlandingv2::VERSION,
        description: "The golumin.io website, as a theme: switch it off and the CMS is headless.",
        author: "Martin Business Consultants", enabled_by_default: true, requires: ">= 1.14",
        homepage: "https://github.com/Martin-Business-Consultants/goluminlandingv2-theme"
      Website.register :goluminlandingv2, name: "GoLumin", version: Goluminlandingv2::VERSION,
        views: Goluminlandingv2::Engine.root.join("app/views"),
        importmap: Importmap::Map.new.draw(Goluminlandingv2::Engine.root.join("config/importmap.rb")),
        # Settings › Themes › Customize.
        design: [
          {name: "header_phone", label: "Show the phone number in the header", type: "boolean", default: true},
          {name: "sticky_cta", label: "Show the call / plan bar at the foot of the screen on phones", type: "boolean", default: true}
        ]
    end
  end
end
