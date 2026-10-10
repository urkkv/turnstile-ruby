# Turnstile Ruby

[![Gem Version](https://badge.fury.io/rb/turnstile-ruby.svg)](https://badge.fury.io/rb/turnstile-ruby)
[![CI](https://github.com/urkkv/turnstile-ruby/actions/workflows/main.yml/badge.svg)](https://github.com/urkkv/turnstile-ruby/actions/workflows/main.yml)

[Cloudflare Turnstile](https://developers.cloudflare.com/turnstile/) for Ruby: view helpers for the widget, controller
helpers for verification, and a small client for the siteverify API.
Turnstile is a CAPTCHA alternative from Cloudflare, similar to Google reCAPTCHA, but lightweight and privacy-friendly.

It works in **Rails, Sinatra, any Rack app and plain Ruby**, and has no runtime dependencies.

---

## ✨ Features

- `turnstile_tags` and `verify_turnstile` helpers, added to Rails automatically
- `Turnstile.verify` for jobs, APIs, Sinatra and plain Ruby, returning error codes and the reply details
- Works with Turbo (Hotwire): widgets keep rendering across Turbo visits
- CSP friendly: script tags carry your nonce, picked up from Rails automatically
- Invisible flow that runs the challenge when the form is submitted
- Translated error messages (en, fr, ja, nl), written to the flash or your model's errors
- Test helpers to stub passing and failing verifications
- No runtime dependencies, Ruby 2.7+

---

## 📦 Installation

Add this line to your Gemfile:

```ruby
gem "turnstile-ruby"
```

And install:

```bash
bundle install
```

---

## ⚙️ Configuration

Get a site key and a secret key from the [Cloudflare dashboard](https://dash.cloudflare.com/?to=/:account/turnstile)
and set them in the environment:

```bash
export TURNSTILE_SITE_KEY="your_site_key"
export TURNSTILE_SECRET_KEY="your_secret_key"
```

Or configure them in code, for Rails in `config/initializers/turnstile.rb`:

```ruby
Turnstile.configure do |config|
  config.site_key   = ENV["TURNSTILE_SITE_KEY"]
  config.secret_key = ENV["TURNSTILE_SECRET_KEY"]
  config.timeout    = 5 # optional, seconds to wait for Cloudflare (default 3)
end
```

| Option | Default | |
|---|---|---|
| `site_key`, `secret_key` | `TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET_KEY` | Your keys |
| `timeout` | `3` | Seconds to wait for Cloudflare when verifying |
| `skip_verify_env` | `["test", "cucumber", "rspec"]` | Environments where verification always passes |
| `handle_timeouts_gracefully` | `true` | Fail verification with a message when Cloudflare is unreachable, instead of raising |
| `hostname` | `nil` | A string or callable the reply's hostname has to match |
| `turbo` | `true` | Render widgets again after Turbo visits |
| `proxy` | `nil` | HTTP proxy URL for the verification request |
| `response_limit` | `2048` | Maximum accepted token length |

For local development Cloudflare has [dummy keys](https://developers.cloudflare.com/turnstile/troubleshooting/testing/)
that work on any host: site key `1x00000000000000000000AA` with secret key `1x0000000000000000000000000000000AA`
always passes.

---

## 🛠 Usage

### Rails

Add the widget to a form:

```erb
<%= form_with model: @user do |form| %>
  <%= form.text_field :email %>
  <%= turnstile_tags %>
  <%= form.submit %>
<% end %>
```

And verify it in the controller:

```ruby
def create
  @user = User.new(user_params)

  if verify_turnstile(model: @user) && @user.save
    redirect_to @user
  else
    render :new, status: :unprocessable_entity
  end
end
```

`verify_turnstile` returns `true` or `false`. On failure it adds an error to the model, or sets
`flash[:turnstile_error]` when no model is given. A missing token fails verification, it does not raise.

| Option | |
|---|---|
| `model:` | Record that gets the error message |
| `attribute:` | Attribute for the error, `:base` by default |
| `message:` | Custom error message |
| `action:` / `hostname:` | Fail unless the reply matches |
| `timeout:` | Seconds to wait, overriding the configuration |
| `secret_key:` | Secret key for this call |
| `response:` | Token to verify, `params["cf-turnstile-response"]` by default |
| `skip_remote_ip: true` | Do not send the visitor's IP to Cloudflare |

`verify_turnstile!` raises `Turnstile::VerifyError` instead of returning `false`, and `turnstile_reply` gives you
Cloudflare's raw reply afterwards.

### Widget options

`turnstile_tags` accepts the
[widget configuration](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/widget-configurations/)
in snake_case, and passes anything else through as HTML attributes:

```erb
<%= turnstile_tags theme: "dark", size: "flexible", action: "signup", appearance: "interaction-only", class: "mt-4" %>
```

`action`, `cdata`, `theme`, `language`, `size`, `appearance`, `execution`, `tabindex`, `retry`, `retry_interval`,
`refresh_expired`, `refresh_timeout`, `response_field`, `response_field_name`, `feedback_enabled`,
`offlabel_show_privacy`, `offlabel_show_help`, `callback`, `error_callback`, `expired_callback`, `timeout_callback`,
`before_interactive_callback`, `after_interactive_callback` and `unsupported_callback` are supported.

| Helper option | |
|---|---|
| `site_key:` | Site key for this widget |
| `nonce:` | CSP nonce for the script tags (automatic in Rails) |
| `turbo: false` | Leave out the Turbo support script |
| `script: false` | Render no script tags, for when you load `api.js` yourself |
| `onload:`, `render:` | Query parameters for `api.js`, for [explicit rendering](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#explicit-rendering) |
| `script_async: false`, `script_defer: false` | Drop `async` / `defer` from the script tag |

### Turbo

Nothing to set up. `api.js` only scans the page once, so with Turbo Drive a widget would stay empty after the first
visit. `turnstile_tags` therefore includes a small inline script that renders widgets after Turbo visits, frame
renders and cache restores. If your Content Security Policy blocks inline scripts and you pass no nonce, the widget
still works on full page loads.

### Content Security Policy

Allow `https://challenges.cloudflare.com` in `script-src` and `frame-src`. In Rails the helpers add your
`content_security_policy_nonce` to their script tags; elsewhere pass `nonce:` yourself.

### Invisible flow

```erb
<%= form_with url: signup_path do |form| %>
  <%= form.text_field :email %>
  <%= invisible_turnstile_tags text: "Sign up", class: "btn" %>
<% end %>
```

This renders a submit button and a widget that stays hidden unless Cloudflare needs the visitor to interact. The
challenge runs when the form is submitted, and the form is sent once the token arrives. Pass `ui: :input` for an
`<input type="submit">`, or `callback: "myFunction"` to receive the token yourself instead of submitting the form.

### Sinatra

```ruby
require "sinatra"
require "turnstile"

helpers Turnstile::Adapters::ViewMethods, Turnstile::Adapters::ControllerMethods

get "/" do
  %(<form action="/verify" method="post">#{turnstile_tags}<button>Submit</button></form>)
end

post "/verify" do
  verify_turnstile ? "Verified" : halt(422, "Verification failed")
end
```

There is a runnable version in [`demo/sinatra`](demo/sinatra).

### Plain Ruby

`Turnstile.verify` works anywhere: API endpoints, background jobs, other frameworks.

```ruby
require "turnstile"

result = Turnstile.verify(token, remote_ip: request.ip)

if result.success?
  puts "Verification passed!"
else
  puts "Verification failed: #{result.error_codes.inspect}"
end
```

It returns a `Turnstile::Response`:

- `success?` → `true` or `false`
- `error_codes` → Cloudflare's [error codes](https://developers.cloudflare.com/turnstile/get-started/server-side-validation/#error-codes),
  plus `hostname-mismatch` / `action-mismatch` when you asked to validate those
- `hostname`, `action`, `cdata`, `challenge_ts`, `metadata` → details of the challenge
- `to_h` → the raw reply

Options: `remote_ip:`, `secret_key:`, `timeout:`, `hostname:`, `action:` and `idempotency_key:`.

A missing token returns a failed response without calling Cloudflare. Unlike `verify_turnstile`, this method does
not skip the test environment, and it raises `Timeout::Error` or `Turnstile::UnreachableError` when Cloudflare
cannot be reached.

---

## 🧪 Testing your app

In the `test` environment `verify_turnstile` always passes and `turnstile_tags` renders an empty container, so your
tests never call Cloudflare. To test what happens when verification fails:

```ruby
require "turnstile/testing"

Turnstile::Testing.with_failure do
  post signups_path, params: { user: { email: "a@example.com" } }
  expect(response).to have_http_status(:unprocessable_entity)
end
```

`Turnstile::Testing.success!`, `failure!("timeout-or-duplicate")` and `reset!` do the same without a block; call
`reset!` after each test when you use them.

---

## 🚀 Development

Clone the repo and install dependencies:

```bash
git clone https://github.com/urkkv/turnstile-ruby.git
cd turnstile-ruby
bundle install
```

Run the specs and RuboCop:

```bash
bundle exec rake
```

---

## 📜 License

This project is licensed under the [MIT License](LICENSE.txt).

---

## 🙌 Contributing

Bug reports and pull requests are welcome at
[https://github.com/urkkv/turnstile-ruby](https://github.com/urkkv/turnstile-ruby).

---

## 🔗 Resources

- [Cloudflare Turnstile Documentation](https://developers.cloudflare.com/turnstile/)
- [RubyGems.org – turnstile-ruby](https://rubygems.org/gems/turnstile-ruby)
- [Changelog](CHANGELOG.md)
