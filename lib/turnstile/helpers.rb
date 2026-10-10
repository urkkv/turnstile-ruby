# frozen_string_literal: true

require "erb"

module Turnstile
  module Helpers
    DEFAULT_ERRORS = {
      turnstile_unreachable: "Oops, we failed to validate your Turnstile response. Please try again.",
      verification_failed: "Turnstile verification failed, please try again."
    }.freeze

    # Options rendered as data-* attributes on the widget, see
    # https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/widget-configurations/
    WIDGET_OPTIONS = %i[
      action cdata callback error_callback expired_callback timeout_callback before_interactive_callback
      after_interactive_callback unsupported_callback theme language tabindex response_field response_field_name
      size retry retry_interval refresh_expired refresh_timeout appearance execution feedback_enabled
      offlabel_show_privacy offlabel_show_help
    ].freeze

    # The only widget options where +false+ is a value, everywhere else it means "leave it out".
    BOOLEAN_OPTIONS = %i[response_field feedback_enabled offlabel_show_privacy offlabel_show_help].freeze

    # Options that control the helper itself and never end up as HTML attributes.
    SETTINGS = %i[
      env site_key sitekey hl onload render script_async script_defer script external_script inline_script
      nonce turbo ui text
    ].freeze

    HELPER_SCRIPT = File.read(File.expand_path("helper.js", __dir__)).gsub(%r{^\s*//.*\n}, "").gsub(/^\s+/, "").freeze

    def self.to_error_message(key)
      default = DEFAULT_ERRORS.fetch(key) { raise ArgumentError, "Unknown Turnstile captcha error - #{key}" }
      to_message("turnstile.errors.#{key}", default)
    end

    def self.to_message(key, default)
      defined?(I18n) ? I18n.translate(key, default: default) : default
    end

    def self.turnstile_tags(options = {})
      if options.key?(:ssl)
        raise(TurnstileError, "SSL is now always true. Please remove 'ssl' from your calls to turnstile_tags.")
      end

      options = options.dup
      settings = extract(options, SETTINGS)
      attributes = data_attributes(options, settings)
      attributes["class"] = ["cf-turnstile", options.delete(:class)].compact.join(" ")

      html = script_tags(settings, helper: turbo?(settings) && settings[:render].to_s != "explicit")
      html << %(<div #{tag_attributes(attributes.merge(options))}></div>\n)
      safe(html)
    end

    # Renders a submit button that runs the challenge when the form is submitted and only then submits it.
    def self.invisible_turnstile_tags(custom = {})
      options = { ui: :button, appearance: "interaction-only" }.merge(custom)
      settings = extract(options, SETTINGS)
      tabindex = options.delete(:tabindex)
      widget = data_attributes(options, settings).merge("data-turnstile-invisible" => true)
      options[:tabindex] = tabindex if tabindex

      html = script_tags(settings, helper: true)
      html << %(<div #{tag_attributes(widget)}></div>\n)
      html << submit_tag(settings, options)
      safe(html)
    end

    private_class_method def self.submit_tag(settings, attributes)
      text = escape(settings[:text])

      case settings[:ui]
      when :button
        %(<button #{tag_attributes({ "type" => "submit" }.merge(attributes))}>#{text}</button>\n)
      when :input
        %(<input #{tag_attributes({ "type" => "submit" }.merge(attributes))} value="#{text}"/>\n)
      else
        raise(TurnstileError, "Turnstile ui `#{settings[:ui]}` is not valid.")
      end
    end

    private_class_method def self.data_attributes(options, settings)
      options[:cdata] = options.delete(:cData) if options.key?(:cData)
      options[:language] ||= settings[:hl] if settings[:hl]
      values = extract(options, WIDGET_OPTIONS)
      return {} if Turnstile.skip_env?(settings[:env])

      site_key = settings[:site_key] || settings[:sitekey] || Turnstile.configuration.site_key!
      values.each_with_object("data-sitekey" => site_key) do |(key, value), attributes|
        next if value.nil? || (value == false && !BOOLEAN_OPTIONS.include?(key))

        attributes["data-#{key.to_s.tr("_", "-")}"] = value.to_s
      end
    end

    private_class_method def self.script_tags(settings, helper:)
      html = +""
      return html if Turnstile.skip_env?(settings[:env]) || settings[:script] == false

      html << api_script_tag(settings) unless settings[:external_script] == false
      html << helper_script_tag(settings) if helper && settings[:inline_script] != false
      html
    end

    private_class_method def self.api_script_tag(settings)
      query = { onload: settings[:onload], render: settings[:render] }.reject { |_, value| value.to_s.empty? }
      url = Turnstile.configuration.api_server_url
      url += "?#{URI.encode_www_form(query)}" unless query.empty?

      attributes = { "src" => url }
      attributes["async"] = true unless settings[:script_async] == false
      attributes["defer"] = true unless settings[:script_defer] == false
      attributes["nonce"] = settings[:nonce] || nil

      %(<script #{tag_attributes(attributes)}></script>\n)
    end

    private_class_method def self.helper_script_tag(settings)
      nonce = settings[:nonce] ? %( nonce="#{escape(settings[:nonce])}") : ""
      %(<script#{nonce}>#{HELPER_SCRIPT}</script>\n)
    end

    private_class_method def self.turbo?(settings)
      settings.fetch(:turbo) { Turnstile.configuration.turbo } != false
    end

    private_class_method def self.extract(options, keys)
      keys.each_with_object({}) { |key, found| found[key] = options.delete(key) if options.key?(key) }
    end

    private_class_method def self.tag_attributes(attributes)
      attributes.reject { |_, value| value.nil? }.map do |name, value|
        value == true ? escape(name) : %(#{escape(name)}="#{escape(value)}")
      end.join(" ")
    end

    private_class_method def self.escape(value)
      ERB::Util.html_escape(value.to_s)
    end

    private_class_method def self.safe(html)
      html.respond_to?(:html_safe) ? html.html_safe : html
    end
  end
end
