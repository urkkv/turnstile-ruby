# frozen_string_literal: true

module Turnstile
  module Adapters
    module ControllerMethods
      private

      # Your private API can be specified in the +options+ hash or preferably
      # using the Configuration.
      def verify_turnstile(options = {})
        options = { model: options } unless options.is_a? Hash
        return true if Turnstile.stubbed_response.nil? && Turnstile.skip_env?(options[:env])

        model = options[:model]
        attribute = options.fetch(:attribute, :base)

        begin
          result = Turnstile.verify(options[:response] || params["cf-turnstile-response"], turnstile_options(options))
          @_turnstile_reply = result.to_h

          if result.success?
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
        rescue Timeout::Error, UnreachableError
          raise TurnstileError, "Turnstile unreachable." unless Turnstile.configuration.handle_timeouts_gracefully

          turnstile_error(
            model,
            attribute,
            options.fetch(:message) { Turnstile::Helpers.to_error_message(:turnstile_unreachable) }
          )
          false
        rescue TurnstileError
          raise
        rescue StandardError => e
          raise TurnstileError, e.message, e.backtrace
        end
      end

      def verify_turnstile!(options = {})
        return true if verify_turnstile(options)

        raise VerifyError, "Turnstile verification failed: #{Array(turnstile_reply.to_h["error-codes"]).join(", ")}"
      end

      # The raw siteverify reply of the last verify_turnstile call.
      def turnstile_reply
        @_turnstile_reply if defined?(@_turnstile_reply)
      end

      def turnstile_options(options)
        return options if options[:skip_remote_ip] || options.key?(:remote_ip)

        remote_ip = if request.respond_to?(:remote_ip)
                      request.remote_ip
                    elsif request.respond_to?(:ip)
                      request.ip
                    end
        remote_ip ? options.merge(remote_ip: remote_ip.to_s) : options
      end

      def turnstile_error(model, attribute, message)
        if model.respond_to?(:errors)
          model.errors.add(attribute, message)
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
