# frozen_string_literal: true

module Turnstile
  module Adapters
    module ViewMethods
      # Renders a turnstile [Checkbox](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/) widget
      def turnstile_tags(options = {})
        ::Turnstile::Helpers.turnstile_tags(options)
      end

      # Renders a Turnstile [Invisible Turnstile captcha](https://developers.cloudflare.com/turnstile/reference/widget-types/#invisible)
      def invisible_turnstile_tags(options = {})
        ::Turnstile::Helpers.invisible_turnstile_tags(options)
      end
    end
  end
end
