# frozen_string_literal: true

require "webmock/rspec"
require "turnstile"
require "turnstile/testing"

VERIFY_URL = Turnstile::Configuration::DEFAULTS.fetch("verify_url")

module SiteverifyHelpers
  # stub_siteverify(success: false, "error-codes": [...]) or stub_siteverify("<html>", status: 502)
  def stub_siteverify(raw_body = nil, status: 200, **reply)
    body = raw_body || JSON.generate(reply.empty? ? { success: true } : reply)
    stub_request(:post, VERIFY_URL).to_return(status: status, body: body)
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include SiteverifyHelpers

  config.before do
    Turnstile.instance_variable_set(:@configuration, nil)
    Turnstile.stubbed_response = nil
    Turnstile.configure do |c|
      c.site_key = "1x00000000000000000000AA"
      c.secret_key = "1x0000000000000000000000000000000AA"
      c.default_env = "production"
    end
  end
end
