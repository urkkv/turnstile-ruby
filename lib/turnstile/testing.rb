# frozen_string_literal: true

require "turnstile"

module Turnstile
  # Helpers for your own test suite. Not loaded by default:
  #
  #   require "turnstile/testing"
  #
  #   Turnstile::Testing.failure!                         # every verification fails
  #   Turnstile::Testing.success!                         # every verification passes
  #   Turnstile::Testing.reset!                           # back to normal
  #   Turnstile::Testing.with_failure { post signup_path } # block form, resets afterwards
  #
  # While a stub is active no request is sent to Cloudflare, and `verify_turnstile`
  # uses the stub even in environments listed in `skip_verify_env`.
  module Testing
    module_function

    def success!(reply = {})
      Turnstile.stubbed_response = Response.new({ "success" => true, "error-codes" => [] }.merge(reply))
    end

    def failure!(*error_codes)
      error_codes = ["invalid-input-response"] if error_codes.empty?
      Turnstile.stubbed_response = Response.new({ "success" => false, "error-codes" => error_codes.flatten })
    end

    def reset!
      Turnstile.stubbed_response = nil
    end

    def with_success(reply = {}, &block)
      with_stub(block) { success!(reply) }
    end

    def with_failure(*error_codes, &block)
      with_stub(block) { failure!(*error_codes) }
    end

    def with_stub(block)
      previous = Turnstile.stubbed_response
      yield
      block.call
    ensure
      Turnstile.stubbed_response = previous
    end
    private_class_method :with_stub
  end
end
