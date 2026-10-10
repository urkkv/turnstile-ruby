# frozen_string_literal: true

require_relative "lib/turnstile/version"

Gem::Specification.new do |spec|
  spec.name     = "turnstile-ruby"
  spec.version  = Turnstile::VERSION
  spec.authors  = ["urkkv"]
  spec.email    = ["urkv@outlook.com"]
  spec.summary  = "Cloudflare Turnstile for Ruby, Rails and Sinatra: widget helpers and token verification"
  spec.description = "Adds Cloudflare Turnstile, the privacy-friendly CAPTCHA alternative, to Rails, Sinatra and " \
                     "plain Ruby apps. Ships view helpers for the widget (Turbo and CSP nonce aware), controller " \
                     "helpers and a small client for the siteverify API, with no runtime dependencies."
  spec.homepage = "https://github.com/urkkv/turnstile-ruby"
  spec.license  = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.files = Dir["lib/**/*", "rails/locales/*.yml", "sig/**/*.rbs", "README.md", "CHANGELOG.md", "LICENSE.txt"]
               .select { |path| File.file?(path) }
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = "#{spec.homepage}/tree/master"
  spec.metadata["changelog_uri"]     = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"]   = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "https://www.rubydoc.info/gems/turnstile-ruby"
end
