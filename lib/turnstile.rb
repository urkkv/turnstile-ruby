# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require "turnstile/version"
require "turnstile/configuration"
require "turnstile/response"
require "turnstile/helpers"
require "turnstile/adapters/controller_methods"
require "turnstile/adapters/view_methods"

require "turnstile/railtie" if defined?(Rails::Railtie)

module Turnstile
  DEFAULT_TIMEOUT = 3

  class TurnstileError < StandardError
  end

  class VerifyError < TurnstileError
  end

  # Raised when Cloudflare answers with something that is not a siteverify reply (a 5xx page, an empty body, ...).
  class UnreachableError < TurnstileError
  end

  class << self
    # A Turnstile::Response returned by every verification instead of calling Cloudflare.
    # Set through Turnstile::Testing (require "turnstile/testing").
    attr_accessor :stubbed_response
  end

  # Gives access to the current Configuration.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Allows easy setting of multiple configuration options. See Configuration
  # for all available options.
  def self.configure
    config = configuration
    yield(config)
  end

  def self.with_configuration(config)
    original_config = {}

    config.each do |key, value|
      original_config[key] = configuration.send(key)
      configuration.send("#{key}=", value)
    end

    yield if block_given?
  ensure
    original_config.each { |key, value| configuration.send("#{key}=", value) }
  end

  def self.site_key
    configuration.site_key
  end

  def self.secret_key
    configuration.secret_key
  end

  def self.skip_env?(env)
    configuration.skip_verify_env.include?(env || configuration.default_env)
  end

  def self.invalid_response?(resp)
    !resp.is_a?(String) || resp.empty? || resp.length > configuration.response_limit
  end

  # Verifies a token with Cloudflare and returns a Turnstile::Response.
  #
  #   result = Turnstile.verify(params["cf-turnstile-response"], remote_ip: request.remote_ip)
  #   result.success?    # => true / false
  #   result.error_codes # => ["timeout-or-duplicate"]
  #
  # Options: +secret_key+, +remote_ip+, +idempotency_key+, +timeout+, +hostname+ and +action+.
  # A missing or oversized token fails without a network call. Network timeouts raise Timeout::Error and
  # unusable replies raise Turnstile::UnreachableError.
  def self.verify(token, options = {})
    return stubbed_response if stubbed_response
    return failure(missing_token_code(token)) if invalid_response?(token)

    reply = api_verification(verify_params(token, options), timeout: options[:timeout])
    errors = []
    errors << "hostname-mismatch" unless hostname_valid?(reply["hostname"], options[:hostname])
    errors << "action-mismatch" unless action_valid?(reply["action"], options[:action])
    Response.new(reply, extra_errors: errors)
  end

  # Kept for backwards compatibility, prefer Turnstile.verify.
  def self.verify_via_api_call(response, options)
    result = verify(response, options)

    if options[:with_reply] == true
      [result.success?, result.to_h]
    else
      result.success?
    end
  end

  def self.hostname_valid?(hostname, validation)
    validation ||= configuration.hostname

    case validation
    when nil, FalseClass then true
    when String then validation == hostname
    else validation.call(hostname)
    end
  end

  def self.action_valid?(action, expected_action)
    case expected_action
    when nil, FalseClass then true
    else action == expected_action.to_s
    end
  end

  def self.http_client_for(uri:, timeout: nil)
    timeout ||= configuration.timeout || DEFAULT_TIMEOUT
    http = if configuration.proxy
             proxy_server = URI.parse(configuration.proxy)
             Net::HTTP::Proxy(proxy_server.host, proxy_server.port, proxy_server.user, proxy_server.password)
           else
             Net::HTTP
           end
    instance = http.new(uri.host, uri.port)
    instance.read_timeout = instance.open_timeout = timeout
    instance.use_ssl = true if uri.port == 443

    instance
  end

  def self.api_verification(verify_hash, timeout: nil)
    uri = URI.parse(configuration.verify_url)
    http_instance = http_client_for(uri: uri, timeout: timeout)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data verify_hash
    reply = JSON.parse(http_instance.request(request).body.to_s)
    raise UnreachableError, "Unexpected reply from Turnstile: #{reply.inspect}" unless reply.is_a?(Hash)

    reply
  rescue JSON::ParserError
    raise UnreachableError, "Turnstile did not return a JSON reply."
  end

  def self.verify_params(token, options)
    params = { "secret" => options.fetch(:secret_key) { configuration.secret_key! }, "response" => token }
    params["remoteip"] = options[:remote_ip].to_s if options[:remote_ip]
    params["idempotency_key"] = options[:idempotency_key].to_s if options[:idempotency_key]
    params
  end
  private_class_method :verify_params

  def self.failure(error_code)
    Response.new({ "success" => false, "error-codes" => [error_code] })
  end
  private_class_method :failure

  def self.missing_token_code(token)
    token.nil? || token == "" ? "missing-input-response" : "invalid-input-response"
  end
  private_class_method :missing_token_code
end
