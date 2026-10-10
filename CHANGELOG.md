## [Unreleased]

## [0.2.0] - 2026-10-06

### Added

- `Turnstile.verify(token, ...)` returns a `Turnstile::Response` (`success?`, `error_codes`, `hostname`, `action`,
  `cdata`, `challenge_ts`, `metadata`, `to_h`) for use outside of controllers.
- Turbo (Hotwire) support: widgets render again after Turbo Drive visits, frame renders and cache restores. On by
  default, turn it off with `turbo: false` or `config.turbo = false`.
- CSP nonces: `nonce:` is added to every script tag, and the Rails helpers pick up `content_security_policy_nonce`
  automatically.
- Widget options `appearance`, `execution`, `tabindex`, `refresh_timeout`, `feedback_enabled`,
  `before_interactive_callback`, `after_interactive_callback`, `unsupported_callback`, `offlabel_show_privacy` and
  `offlabel_show_help`.
- `config.timeout`, `Turnstile.site_key`, `Turnstile.secret_key` and the `idempotency_key:` verify option.
- `Turnstile::Testing` (`require "turnstile/testing"`) to stub verification results in your own tests.
- `lib/turnstile-ruby.rb`, so a plain `gem "turnstile-ruby"` is auto-required by Bundler.
- A spec suite, run on Ruby 2.7 to 4.0.

### Changed

- `invisible_turnstile_tags` is reimplemented. It used to render the widget inside the submit button and submit the
  form as soon as the page loaded. It now renders a hidden widget next to the button and runs the challenge when the
  form is submitted. The button no longer gets the `cf-turnstile` class.
- The `hl:` option sets `data-language` instead of an unused `hl` query parameter on the script.
- `verify_turnstile!` raises `Turnstile::VerifyError` with a readable message instead of the reply hash.
- `turnstile_tags` emits a small inline script for Turbo support (see above).
- Ruby 2.7 or newer is required.

### Fixed

- A missing `cf-turnstile-response` parameter raised `TurnstileError` (a 500) instead of failing verification.
- `verify_turnstile(model: record)` called `record.new` and raised when verification failed. A `model:` without
  `errors` (for example a class) falls back to the flash.
- The `timeout:` option was ignored.
- A non-JSON reply from Cloudflare raised instead of being handled like a timeout.
- Attribute values were not HTML-escaped.
- Options such as `inline_script` and `external_script` leaked into the widget's HTML attributes.
- `response_field: false` was dropped instead of rendered. Other options still leave out `false` and `nil`.
- `Turnstile::Helpers.to_error_message` raised `NoMethodError` for unknown keys.
- `LICENSE.txt` was missing from the packaged gem.

## [0.1.0] - 2023-02-23

- Initial release
