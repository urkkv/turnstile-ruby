# frozen_string_literal: true

module Turnstile
  # The outcome of a token verification, wrapping Cloudflare's siteverify reply.
  #
  #   result = Turnstile.verify(token)
  #   result.success?     # => false
  #   result.error_codes  # => ["invalid-input-response"]
  #   result.hostname     # => "example.com"
  #
  class Response
    def initialize(reply, extra_errors: [])
      @reply = reply
      @extra_errors = extra_errors
    end

    def success?
      @reply["success"].to_s == "true" && @extra_errors.empty?
    end

    # Cloudflare's error codes, plus "hostname-mismatch" / "action-mismatch" when the
    # reply does not match the hostname or action you asked to validate.
    def error_codes
      Array(@reply["error-codes"]) + @extra_errors
    end

    def hostname
      @reply["hostname"]
    end

    def action
      @reply["action"]
    end

    def cdata
      @reply["cdata"]
    end

    # ISO 8601 timestamp of the challenge, as sent by Cloudflare.
    def challenge_ts
      @reply["challenge_ts"]
    end

    def metadata
      @reply["metadata"] || {}
    end

    # The raw siteverify reply.
    def to_h
      @reply
    end
  end
end
