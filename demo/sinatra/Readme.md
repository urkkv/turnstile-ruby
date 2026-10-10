A small Sinatra app with Turbo Drive that shows the widget, the invisible flow and server-side verification.

```bash
bundle install
bundle exec rackup -p 4567
```

Then go to <http://localhost:4567>. It uses Cloudflare's dummy keys, which always pass. Set `TURNSTILE_SITE_KEY` and
`TURNSTILE_SECRET_KEY` to use your own.
