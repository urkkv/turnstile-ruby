# frozen_string_literal: true

require_relative "lib/turnstile/version"

Gem::Specification.new do |spec|
  spec.name     = "turnstile-ruby"
  spec.version  = Turnstile::VERSION
  spec.authors  = ["urkkv"]
  spec.email    = ["urkv@outlook.com"]
  spec.summary  = spec.description = "Helper for Turnstile Captcha API"
  spec.homepage = "http://github.com/urkkv/turnstile-ruby"
  spec.license  = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.files    = `git ls-files lib rails README.md CHANGELOG.md LICENSE`.split("\n")

  spec.metadata["allowed_push_host"]  = "http://github.com/urkkv/turnstile-ruby"
  spec.metadata["homepage_uri"]       = spec.homepage
  spec.metadata["source_code_uri"]    = "http://github.com/urkkv/turnstile-ruby"
  spec.metadata["changelog_uri"]      = "http://github.com/urkkv/turnstile-ruby"
  spec.metadata[ "allowed_push_host"] = "https://rubygems.org"

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "json"
  spec.add_development_dependency "bump"
  spec.add_development_dependency "i18n"
  spec.add_development_dependency "maxitest"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "webmock"
end
