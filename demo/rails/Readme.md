This demo is a Rails 5.2 app and needs an older Ruby (2.x) to run. For a demo that runs on current Rubies, see
[`demo/sinatra`](../sinatra).

To run the turnstile examples (with Cloudflare's dummy keys from the `.env`), start the server with `rails s`. Then
go to <http://localhost:3000/captchas>.

To use your own keys, set these environment variables:
```
  export TURNSTILE_SITE_KEY=site_key
  export TURNSTILE_SECRET_KEY=secret_key
```
and start the server with `rails s`. Then go to <http://localhost:3000/captchas>.
