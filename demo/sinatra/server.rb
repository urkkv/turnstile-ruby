require "bundler/setup"
require "sinatra"
require "turnstile-ruby"

# Cloudflare's dummy keys: they work on any host and always pass.
# Other outcomes: https://developers.cloudflare.com/turnstile/troubleshooting/testing/
# Use your own from https://dash.cloudflare.com/ by setting the environment variables.
Turnstile.configure do |config|
  config.site_key   = ENV.fetch("TURNSTILE_SITE_KEY", "1x00000000000000000000AA")
  config.secret_key = ENV.fetch("TURNSTILE_SECRET_KEY", "1x0000000000000000000000000000000AA")
end

helpers Turnstile::Adapters::ViewMethods, Turnstile::Adapters::ControllerMethods

# Turbo Drive is loaded to show that widgets keep rendering across Turbo visits.
def page(title, body)
  <<~HTML
    <!doctype html>
    <html>
      <head>
        <title>#{title}</title>
        <script src="https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.13/dist/turbo.es2017-umd.js"></script>
      </head>
      <body>
        <nav><a href="/">Home</a> | <a href="/widget">Widget</a> | <a href="/invisible">Invisible</a></nav>
        <h1>#{title}</h1>
        #{body}
      </body>
    </html>
  HTML
end

get "/" do
  page "Home", "<p>No widget on this page.</p>"
end

get "/widget" do
  page "Widget", <<~HTML
    <form action="/verify" method="post">
      #{turnstile_tags theme: "light", action: "demo"}
      <button type="submit">Submit</button>
    </form>
  HTML
end

get "/invisible" do
  page "Invisible", <<~HTML
    <form action="/verify" method="post">
      <input name="name" placeholder="Your name" required>
      #{invisible_turnstile_tags text: "Submit", id: "invisible-submit"}
    </form>
  HTML
end

post "/verify" do
  if verify_turnstile
    redirect to("/result"), 303
  else
    status 422
    page "Failed", "<p id=\"result\">Verification failed: #{turnstile_reply.to_h["error-codes"]}</p>"
  end
end

get "/result" do
  page "Verified", "<p id=\"result\">Turnstile verification passed.</p>"
end
