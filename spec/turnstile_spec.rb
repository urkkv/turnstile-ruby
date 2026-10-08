# frozen_string_literal: true

RSpec.describe Turnstile do
  it "has a version number" do
    expect(Turnstile::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it "loads through the gem name, as Bundler does for `gem \"turnstile-ruby\"`" do
    expect { require "turnstile-ruby" }.not_to raise_error
  end

  it "exposes the configured keys" do
    expect(Turnstile.site_key).to eq("1x00000000000000000000AA")
    expect(Turnstile.secret_key).to eq("1x0000000000000000000000000000000AA")
  end

  describe ".with_configuration" do
    it "restores the previous values" do
      Turnstile.with_configuration(site_key: "temporary") do
        expect(Turnstile.site_key).to eq("temporary")
      end
      expect(Turnstile.site_key).to eq("1x00000000000000000000AA")
    end
  end

  describe ".verify" do
    it "returns a successful response for a valid token" do
      stub_siteverify(success: true, hostname: "example.com", action: "login", cdata: "abc",
                      challenge_ts: "2026-01-01T00:00:00.000Z", metadata: { interactive: false })

      result = Turnstile.verify("token")

      expect(result).to be_a(Turnstile::Response)
      expect(result.success?).to be(true)
      expect(result.error_codes).to eq([])
      expect(result.hostname).to eq("example.com")
      expect(result.action).to eq("login")
      expect(result.cdata).to eq("abc")
      expect(result.challenge_ts).to eq("2026-01-01T00:00:00.000Z")
      expect(result.metadata).to eq("interactive" => false)
      expect(result.to_h).to include("success" => true)
    end

    it "returns the error codes for a rejected token" do
      stub_siteverify(success: false, "error-codes": ["timeout-or-duplicate"])

      result = Turnstile.verify("token")

      expect(result.success?).to be(false)
      expect(result.error_codes).to eq(["timeout-or-duplicate"])
    end

    it "sends the secret, token, remote ip and idempotency key" do
      request = stub_siteverify.with(
        body: { "secret" => "other-secret", "response" => "token", "remoteip" => "1.2.3.4", "idempotency_key" => "k" }
      )

      Turnstile.verify("token", secret_key: "other-secret", remote_ip: "1.2.3.4", idempotency_key: "k")

      expect(request).to have_been_requested
    end

    it "fails without calling Cloudflare when the token is missing or malformed" do
      expect(Turnstile.verify(nil).error_codes).to eq(["missing-input-response"])
      expect(Turnstile.verify("").error_codes).to eq(["missing-input-response"])
      expect(Turnstile.verify(["token"]).error_codes).to eq(["invalid-input-response"])
      expect(Turnstile.verify("x" * 2049).error_codes).to eq(["invalid-input-response"])
      expect(Turnstile.verify(nil).success?).to be(false)
      expect(a_request(:post, VERIFY_URL)).not_to have_been_made
    end

    it "fails when the hostname does not match" do
      stub_siteverify(success: true, hostname: "evil.example")

      result = Turnstile.verify("token", hostname: "example.com")

      expect(result.success?).to be(false)
      expect(result.error_codes).to eq(["hostname-mismatch"])
    end

    it "validates the hostname from the configuration, including callables" do
      stub_siteverify(success: true, hostname: "app.example.com")
      Turnstile.configuration.hostname = ->(hostname) { hostname.end_with?(".example.com") }

      expect(Turnstile.verify("token").success?).to be(true)
    end

    it "fails when the action does not match" do
      stub_siteverify(success: true, action: "login")

      expect(Turnstile.verify("token", action: :signup).error_codes).to eq(["action-mismatch"])
      expect(Turnstile.verify("token", action: :login).success?).to be(true)
    end

    it "uses the timeout option, then the configured timeout" do
      stub_siteverify
      timeouts = []
      allow(Turnstile).to receive(:http_client_for).and_wrap_original do |original, **args|
        original.call(**args).tap { |http| timeouts << http.read_timeout }
      end

      Turnstile.verify("token", timeout: 10)
      Turnstile.configuration.timeout = 7
      Turnstile.verify("token")

      expect(timeouts).to eq([10, 7])
    end

    it "raises Timeout::Error when Cloudflare does not answer in time" do
      stub_request(:post, VERIFY_URL).to_timeout

      expect { Turnstile.verify("token") }.to raise_error(Timeout::Error)
    end

    it "raises UnreachableError when the reply is not JSON" do
      stub_siteverify("<html>502 Bad Gateway</html>", status: 502)

      expect { Turnstile.verify("token") }.to raise_error(Turnstile::UnreachableError)
    end

    it "raises when no secret key is configured" do
      Turnstile.configuration.secret_key = nil

      expect { Turnstile.verify("token") }.to raise_error(Turnstile::TurnstileError, /secret key/)
    end
  end

  describe ".verify_via_api_call" do
    it "returns a boolean, or the reply as well when asked" do
      stub_siteverify(success: true, hostname: "example.com")

      expect(Turnstile.verify_via_api_call("token", {})).to be(true)
      expect(Turnstile.verify_via_api_call("token", with_reply: true))
        .to eq([true, { "success" => true, "hostname" => "example.com" }])
    end
  end
end
