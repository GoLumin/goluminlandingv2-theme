# frozen_string_literal: true

# The website's scripts (Website.theme.importmap), apart from the admin's.
# The layout serves them from the theme itself (Goluminlandingv2Helper#gl_javascript_tags).
pin "goluminlandingv2", to: "goluminlandingv2/site.js"
pin_all_from Goluminlandingv2::Engine.root.join("app/javascript/goluminlandingv2"), under: "goluminlandingv2", to: "goluminlandingv2"
