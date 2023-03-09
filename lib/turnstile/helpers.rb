# frozen_string_literal: true

module Turnstile
  module Helpers
    DEFAULT_ERRORS = {
      turnstile_unreachable: 'Oops, we failed to validate your Turnstile response. Please try again.',
      verification_failed: 'Turnstile verification failed, please try again.'
    }.freeze

    def self.to_error_message(key)
      default = DEFAULT_ERRORS.fetch(key) { raise ArgumentError "Unknown Turnstile captcha error - #{key}" }
      to_message("turnstile.errors.#{key}", default)
    end

    if defined?(I18n)
      def self.to_message(key, default)
        I18n.translate(key, default: default)
      end
    else
      def self.to_message(_key, default)
        default
      end
    end

    def self.turnstile_tags(options)
      if options.key?(:ssl)
        raise(TurnstileError, "SSL is now always true. Please remove 'ssl' from your calls to turnstile_tags.")
      end

      html, tag_attributes = components(options.dup)
      html << %(<div #{tag_attributes}></div>\n)

      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    def self.invisible_turnstile_tags(custom)
      options = { callback: 'javascriptCallback', ui: :button }.merge(custom)
      text = options.delete(:text)
      html, tag_attributes = components(options.dup)
      html << default_callback(options) if default_callback_required?(options)

      case options[:ui]
      when :button
        html << %(<button type="submit" #{tag_attributes}>#{text}</button>\n)
      when :input
        html << %(<input type="submit" #{tag_attributes} value="#{text}"/>\n)
      else
        raise(TurnstileError, "Turnstile ui `#{options[:ui]}` is not valid.")
      end
      html.respond_to?(:html_safe) ? html.html_safe : html
    end

    private_class_method def self.components(options)
      html = +''
      attributes = {}

      options = options.dup
      env = options.delete(:env)
      class_attribute = options.delete(:class)
      site_key = options.delete(:site_key)
      hl = options.delete(:hl)
      onload = options.delete(:onload)
      render = options.delete(:render)
      script_async = options.delete(:script_async)
      script_defer = options.delete(:script_defer)
      skip_script = (options.delete(:script) == false) || (options.delete(:external_script) == false)
      ui = options.delete(:ui)

      data_attribute_keys = %i[sitekey action cData callback expired_callback
                               timeout_callback error_callback theme language response_field
                               response_field_name size retry retry_interval refresh_expired]
      # data_attribute_keys << :tabindex unless ui == :button # TODO:: Remove me
      data_attributes = {}
      data_attribute_keys.each do |data_attribute|
        value = options.delete(data_attribute)
        data_attributes["data-#{data_attribute.to_s.tr('_', '-')}"] = value if value
      end

      unless Turnstile.skip_env?(env)
        site_key ||= Turnstile.configuration.site_key!
        script_url = Turnstile.configuration.api_server_url
        query_params = hash_to_query(
          hl: hl,
          onload: onload,
          render: render
        )
        script_url += "?#{query_params}" unless query_params.empty?
        async_attr = "async" if script_async != false
        defer_attr = "defer" if script_defer != false
        html << %(<script src="#{script_url}" #{async_attr} #{defer_attr}></script>\n) unless skip_script
        attributes["data-sitekey"] = site_key
        attributes.merge! data_attributes
      end

      # The remaining options will be added as attributes on the tag.
      attributes["class"] = "cf-turnstile #{class_attribute}"
      tag_attributes = attributes.merge(options).map { |k, v| %(#{k}="#{v}") }.join(" ")

      [html, tag_attributes]
    end

    private_class_method def self.hash_to_query(hash)
      hash.delete_if { |_, val| val.nil? || val.empty? }.to_a.map { |pair| pair.join('=') }.join('&')
    end

    private_class_method def self.default_callback_required?(options)
      options[:callback] == 'javascriptCallback' &&
      !Turnstile.skip_env?(options[:env]) &&
      options[:script] != false &&
      options[:inline_script] != false
    end

    private_class_method def self.default_callback(options = {})
      selector_attr = options[:id] ? "##{options[:id]}" : ".cf-turnstile"

      <<-HTML
        <script>
          var javascriptCallback = function () {
            var closestForm = function (ele) {
              var curEle = ele.parentNode;
              while (curEle.nodeName !== 'FORM' && curEle.nodeName !== 'BODY'){
                curEle = curEle.parentNode;
              }
              return curEle.nodeName === 'FORM' ? curEle : null
            };

            var el = document.querySelector("#{selector_attr}")
            if (!!el) {
              var form = closestForm(el);
              if (form) {
                form.submit();
              }
            }
          };
        </script>
      HTML
    end
  end
end
