# Turnstile Ruby

[![Gem Version](https://badge.fury.io/rb/turnstile-ruby.svg)](https://badge.fury.io/rb/turnstile-ruby)
[![Build Status](https://github.com/urkkv/turnstile-ruby/actions/workflows/test.yml/badge.svg)](https://github.com/urkkv/turnstile-ruby/actions)

A simple Ruby client for verifying [Cloudflare Turnstile](https://developers.cloudflare.com/turnstile/) tokens.
Turnstile is a CAPTCHA alternative from Cloudflare, similar to Google reCAPTCHA, but lightweight and privacy-friendly.

This gem makes it easy to integrate Turnstile into Ruby and Rails applications.

---

## ✨ Features

- Verify Turnstile tokens with Cloudflare’s API
- Lightweight, no heavy dependencies
- Works with plain Ruby and Ruby on Rails
- Provides meaningful error codes and success flags
- Simple configuration via environment variables or initializer

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

Or install directly with:

```bash
gem install turnstile-ruby
```

---

## ⚙️ Configuration

Set your **Cloudflare Turnstile Site Key** and **Secret Key** in environment variables:

```bash
export TURNSTILE_SITE_KEY="your_site_key"
export TURNSTILE_SECRET_KEY="your_secret_key"
```

For Rails, you can create an initializer (`config/initializers/turnstile.rb`):

```ruby
Turnstile.configure do |config|
  config.site_key   = ENV["TURNSTILE_SITE_KEY"]
  config.secret_key = ENV["TURNSTILE_SECRET_KEY"]
  config.timeout    = 5 # optional, in seconds
end
```

---

## 🛠 Usage

### Rails Views

Embed the Turnstile widget:

```erb
<form action="/signup" method="POST">
  <!-- Your form fields -->

  <div class="cf-turnstile"
       data-sitekey="<%= Turnstile.site_key %>">
  </div>

  <button type="submit">Submit</button>
</form>

<script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
```

### Rails Controller

Verify the token on form submission:

```ruby
def create
  token = params["cf-turnstile-response"]

  result = Turnstile.verify(token, remote_ip: request.remote_ip)

  if result.success?
    # proceed with signup
  else
    flash[:error] = "Turnstile verification failed: #{result.error_codes.join(", ")}"
    render :new
  end
end
```

### Plain Ruby Example

```ruby
require "turnstile"

token = "client-submitted-token"
result = Turnstile.verify(token)

if result.success?
  puts "Verification passed!"
else
  puts "Verification failed: #{result.error_codes.inspect}"
end
```

---

## ✅ Response Object

`Turnstile.verify` returns a `Turnstile::Response` object with:

- `success?` → `true` or `false`  
- `error_codes` → array of error codes  
- `hostname` → hostname (if provided)  
- `challenge_ts` → challenge timestamp (if provided)  

---

## 🚀 Development

Clone the repo and install dependencies:

```bash
git clone https://github.com/urkkv/turnstile-ruby.git
cd turnstile-ruby
bundle install
```

Run tests:

```bash
bundle exec rspec
```

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙌 Contributing

Bug reports and pull requests are welcome at  
[https://github.com/urkkv/turnstile-ruby](https://github.com/urkkv/turnstile-ruby).

---

## 🔗 Resources

- [Cloudflare Turnstile Documentation](https://developers.cloudflare.com/turnstile/)  
- [RubyGems.org – turnstile-ruby](https://rubygems.org/gems/turnstile-ruby)  
