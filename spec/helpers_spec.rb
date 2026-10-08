# frozen_string_literal: true

RSpec.describe Turnstile::Helpers do
  let(:api_js) { "https://challenges.cloudflare.com/turnstile/v0/api.js" }

  describe ".turnstile_tags" do
    it "renders the script and the widget" do
      html = described_class.turnstile_tags

      expect(html).to include(%(<script src="#{api_js}" async defer))
      expect(html).to include(%(<div data-sitekey="1x00000000000000000000AA" class="cf-turnstile"></div>))
    end

    it "raises without a site key" do
      Turnstile.configuration.site_key = nil

      expect { described_class.turnstile_tags }.to raise_error(Turnstile::TurnstileError, /site key/)
    end

    it "accepts a site key per call" do
      expect(described_class.turnstile_tags(site_key: "other")).to include(%(data-sitekey="other"))
    end

    it "renders widget options as data attributes" do
      html = described_class.turnstile_tags(
        theme: "dark", size: "flexible", action: "login", cData: "abc", appearance: "interaction-only",
        execution: "execute", tabindex: 2, retry_interval: 8000, refresh_expired: "manual", refresh_timeout: "never",
        feedback_enabled: false, response_field_name: "token", callback: "onToken", error_callback: "onError",
        before_interactive_callback: "onBefore", offlabel_show_help: true, hl: "fr"
      )

      expect(html).to include(
        %(data-theme="dark"), %(data-size="flexible"), %(data-action="login"), %(data-cdata="abc"),
        %(data-appearance="interaction-only"), %(data-execution="execute"), %(data-tabindex="2"),
        %(data-retry-interval="8000"), %(data-refresh-expired="manual"), %(data-refresh-timeout="never"),
        %(data-feedback-enabled="false"), %(data-response-field-name="token"), %(data-callback="onToken"),
        %(data-error-callback="onError"), %(data-before-interactive-callback="onBefore"),
        %(data-offlabel-show-help="true"), %(data-language="fr")
      )
      expect(html).not_to match(/ (appearance|execution|tabindex)=/)
    end

    it "leaves out options that are nil or false, as in `theme: dark? && \"dark\"`" do
      html = described_class.turnstile_tags(theme: false, size: nil, id: nil)

      expect(html).to include(%(<div data-sitekey="1x00000000000000000000AA" class="cf-turnstile"></div>))
    end

    it "renders false for the boolean options" do
      html = described_class.turnstile_tags(response_field: false, feedback_enabled: false)

      expect(html).to include(%(data-response-field="false" data-feedback-enabled="false"))
    end

    it "passes other options through as HTML attributes" do
      html = described_class.turnstile_tags(id: "captcha", class: "mt-4", "data-controller": "captcha")

      expect(html).to include(%(class="cf-turnstile mt-4" id="captcha" data-controller="captcha"))
    end

    it "escapes attribute values" do
      html = described_class.turnstile_tags(action: %("><script>alert(1)</script>), script: false)

      expect(html).to include(%(data-action="&quot;&gt;&lt;script&gt;alert(1)&lt;/script&gt;"))
      expect(html).not_to include("<script>alert(1)")
    end

    it "adds onload and render to the script url" do
      html = described_class.turnstile_tags(onload: "onTurnstile", render: "explicit")

      expect(html).to include(%(src="#{api_js}?onload=onTurnstile&amp;render=explicit"))
    end

    it "can drop async and defer" do
      html = described_class.turnstile_tags(script_async: false, script_defer: false, turbo: false)

      expect(html).to include(%(<script src="#{api_js}"></script>))
    end

    it "renders no scripts with script: false" do
      html = described_class.turnstile_tags(script: false)

      expect(html).not_to include("<script")
      expect(html).not_to include("script=")
    end

    it "can skip only the external or only the inline script" do
      expect(described_class.turnstile_tags(external_script: false)).not_to include("api.js")
      expect(described_class.turnstile_tags(external_script: false)).to include("turnstileRuby")
      expect(described_class.turnstile_tags(inline_script: false)).to include("api.js")
      expect(described_class.turnstile_tags(inline_script: false)).not_to include("turnstileRuby")
    end

    it "adds the nonce to every script" do
      html = described_class.turnstile_tags(nonce: "abc123")

      expect(html.scan("<script").size).to eq(2)
      expect(html.scan(%(nonce="abc123")).size).to eq(2)
      expect(html).not_to match(/<div[^>]*nonce/)
    end

    it "renders nothing but the container in skipped environments" do
      html = described_class.turnstile_tags(env: "test", theme: "dark")

      expect(html).to eq(%(<div class="cf-turnstile"></div>\n))
    end

    it "rejects the removed ssl option" do
      expect { described_class.turnstile_tags(ssl: true) }.to raise_error(Turnstile::TurnstileError, /SSL/)
    end

    describe "Turbo support" do
      it "is on by default" do
        html = described_class.turnstile_tags

        expect(html).to include(%(<script src="#{api_js}" async defer></script>))
        expect(html).to include("turbo:render")
      end

      it "can be turned off per call or globally" do
        expect(described_class.turnstile_tags(turbo: false)).to eq(<<~HTML)
          <script src="#{api_js}" async defer></script>
          <div data-sitekey="1x00000000000000000000AA" class="cf-turnstile"></div>
        HTML

        Turnstile.configuration.turbo = false
        expect(described_class.turnstile_tags).not_to include("turnstileRuby")
      end

      it "stays out of the way of explicit rendering" do
        expect(described_class.turnstile_tags(render: "explicit")).not_to include("turnstileRuby")
      end
    end
  end

  describe ".invisible_turnstile_tags" do
    it "renders a hidden widget container and a submit button" do
      html = described_class.invisible_turnstile_tags(text: "Save", id: "save", class: "btn")

      expect(html).to include(
        %(<div data-sitekey="1x00000000000000000000AA" data-appearance="interaction-only" ) +
        %(data-turnstile-invisible></div>)
      )
      expect(html).to include(%(<button type="submit" id="save" class="btn">Save</button>))
      expect(html).to include("api.js", "turnstileRuby")
      expect(html).not_to include(%(class="cf-turnstile))
    end

    it "can render an input" do
      html = described_class.invisible_turnstile_tags(text: %(Save "it"), ui: :input, tabindex: 3)

      expect(html).to include(%(<input type="submit" tabindex="3" value="Save &quot;it&quot;"/>))
    end

    it "keeps a custom callback on the widget" do
      expect(described_class.invisible_turnstile_tags(callback: "onToken")).to include(%(data-callback="onToken"))
    end

    it "escapes the button text" do
      expect(described_class.invisible_turnstile_tags(text: "<b>Go</b>")).to include("&lt;b&gt;Go&lt;/b&gt;")
    end

    it "rejects an unknown ui" do
      expect { described_class.invisible_turnstile_tags(ui: :link) }
        .to raise_error(Turnstile::TurnstileError, /ui `link` is not valid/)
    end

    it "renders no scripts or site key in skipped environments" do
      html = described_class.invisible_turnstile_tags(env: "test", text: "Save")

      expect(html).to eq(%(<div data-turnstile-invisible></div>\n<button type="submit">Save</button>\n))
    end
  end

  describe ".to_error_message" do
    it "returns the default messages" do
      expect(described_class.to_error_message(:verification_failed)).to match(/verification failed/)
      expect(described_class.to_error_message(:turnstile_unreachable)).to match(/failed to validate/)
    end

    it "raises ArgumentError for an unknown key" do
      expect { described_class.to_error_message(:bogus) }.to raise_error(ArgumentError, /bogus/)
    end

    it "uses I18n when it is loaded" do
      require "i18n"
      I18n.backend.store_translations(:en, turnstile: { errors: { verification_failed: "Translated" } })

      expect(described_class.to_error_message(:verification_failed)).to eq("Translated")
    ensure
      I18n.backend.reload!
    end
  end
end
