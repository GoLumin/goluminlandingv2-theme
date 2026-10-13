# frozen_string_literal: true

# The site as an app on a home screen.
json.name gl_name
json.short_name "GoLumin"
json.start_url "/"
json.display "standalone"
json.theme_color "#faf9fc"
json.background_color "#faf9fc"
json.icons [{src: gl_asset_path("apple-touch-icon.png"), sizes: "180x180", type: "image/png"}, {src: gl_favicon_href, sizes: "any", type: "image/svg+xml"}]
