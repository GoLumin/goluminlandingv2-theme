# frozen_string_literal: true

require_relative "lib/goluminlandingv2/version"

Gem::Specification.new do |spec|
  spec.name = "goluminlandingv2"
  spec.version = Goluminlandingv2::VERSION
  spec.summary = "The GoLumin website, as a CMS theme"
  spec.authors = ["Martin Business Consultants"]
  spec.files = Dir["{app,config,lib}/**/*"]
  spec.required_ruby_version = ">= 3.3"
  spec.add_dependency "rails", ">= 8.1"
end
