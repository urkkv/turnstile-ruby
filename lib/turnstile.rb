# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

require 'turnstile/configuration'
require 'turnstile/helpers'
require 'turnstile/adapters/controller_methods'
require 'turnstile/adapters/view_methods'

if defined?(Rails)
  require 'turnstile/railtie'
end

module Turnstile
  DEFAULT_TIMEOUT = 3

  class TurnstileError < StandardError
  end

  class VerifyError < TurnstileError
  end

  # Gives access to the current Configuration.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Allows easy setting of multiple configuration options. See Configuration
  # for all available options.
  #--
  # The temp assignment is only used to get a nicer rdoc. Feel free to remove
  # this hack.
  #++
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

  def self.skip_env?(env)
    configuration.skip_verify_env.include?(env || configuration.default_env)
  end

  def self.invalid_response?(resp)
    resp.empty? || resp.length > configuration.response_limit
  end

  def self.verify_via_api_call(response, options)
    secret_key = options.fetch(:secret_key) { configuration.secret_key! }
    verify_hash = { 'secret' => secret_key, 'response' => response }
    verify_hash['remoteip'] = options[:remote_ip] if options.key?(:remote_ip)

    reply = api_verification(verify_hash, timeout: options[:timeout])
    success = reply['success'].to_s == 'true' &&
      hostname_valid?(reply['hostname'], options[:hostname]) &&
      action_valid?(reply['action'], options[:action])

    if options[:with_reply] == true
      [success, reply]
    else
      success
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
    else action == expected_action
    end
  end

  def self.http_client_for(uri:, timeout: nil)
    timeout ||= DEFAULT_TIMEOUT
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
    http_instance = http_client_for(uri: uri, timeout: nil)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data verify_hash
    JSON.parse(http_instance.request(request).body)
  end
end
