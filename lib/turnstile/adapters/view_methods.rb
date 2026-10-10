# frozen_string_literal: true

module Turnstile
  module Adapters
    module ViewMethods
      # Renders a Turnstile [widget](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/)
      def turnstile_tags(options = {})
        ::Turnstile::Helpers.turnstile_tags(turnstile_nonce(options))
      end

      # Renders a submit button that runs an [invisible](https://developers.cloudflare.com/turnstile/concepts/widget/)
      # challenge when the form is submitted
      def invisible_turnstile_tags(options = {})
        ::Turnstile::Helpers.invisible_turnstile_tags(turnstile_nonce(options))
      end

      private

      # Picks up the Rails CSP nonce unless one was passed in.
      def turnstile_nonce(options)
        return options if options.key?(:nonce) || !respond_to?(:content_security_policy_nonce)

        options.merge(nonce: content_security_policy_nonce)
      end
    end
  end
end
