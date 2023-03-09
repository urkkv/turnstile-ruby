# frozen_string_literal: true

module Turnstile
  module Adapters
    module ControllerMethods
      private

      # Your private API can be specified in the +options+ hash or preferably
      # using the Configuration.
      def verify_turnstile(options = {})
        options = {model: options} unless options.is_a? Hash
        return true if Turnstile.skip_env?(options[:env])

        model = options[:model]
        attribute = options.fetch(:attribute, :base)
        turnstile_response = options[:response] || params['cf-turnstile-response']

        begin
          verified = if Turnstile.invalid_response?(turnstile_response)
            false
          else
            unless options[:skip_remote_ip]
              remoteip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
              options = options.merge(remote_ip: remoteip.to_s) if remoteip
            end

            success, @_turnstile_reply =
              Turnstile.verify_via_api_call(turnstile_response, options.merge(with_reply: true))
            success
          end

          if verified
            flash.delete(:turnstile_error) if turnstile_flash_supported? && !model
            true
          else
            turnstile_error(
              model,
              attribute,
              options.fetch(:message) { Turnstile::Helpers.to_error_message(:verification_failed) }
            )
            false
          end
        rescue Timeout::Error
          if Turnstile.configuration.handle_timeouts_gracefully
            turnstile_error(
              model,
              attribute,
              options.fetch(:message) { Turnstile::Helpers.to_error_message(:turnstile_unreachable) }
            )
            false
          else
            raise TurnstileError, 'Turnstile unreachable.'
          end
        rescue StandardError => e
          raise TurnstileError, e.message, e.backtrace
        end
      end

      def verify_turnstile!(options = {})
        verify_turnstile(options) || raise(VerifyError, turnstile_reply)
      end

      def turnstile_reply
        @_turnstile_reply if defined?(@_turnstile_reply)
      end

      def turnstile_error(model, attribute, message)
        if model
          model.new.errors.add(attribute, message)
        elsif turnstile_flash_supported?
          flash[:turnstile_error] = message
        end
      end

      def turnstile_flash_supported?
        request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
      end

    end
  end
end
