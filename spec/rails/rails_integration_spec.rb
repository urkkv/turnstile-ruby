# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require "action_controller/railtie"
require "rack/test"
require "spec_helper"
require "turnstile/railtie"

class TurnstileTestApp < Rails::Application
  config.eager_load = false
  config.secret_key_base = "0" * 64
  config.hosts.clear
  config.logger = Logger.new(nil)
  config.action_controller.allow_forgery_protection = false
  config.i18n.available_locales = %i[en fr]
  config.content_security_policy do |policy|
    policy.script_src :self, "https://challenges.cloudflare.com"
  end
  config.content_security_policy_nonce_generator = ->(_request) { "rails-nonce" }
end

class SignupsController < ActionController::Base
  def new
    render inline: "<form><%= turnstile_tags theme: 'dark' %><%= invisible_turnstile_tags text: 'Go' %></form>"
  end

  def create
    if verify_turnstile(action: "signup")
      render plain: "verified"
    else
      render plain: flash[:turnstile_error], status: 422
    end
  end
end

TurnstileTestApp.initialize!
TurnstileTestApp.routes.draw do
  get "/signups/new" => "signups#new"
  post "/signups" => "signups#create"
end

RSpec.describe "Rails integration" do
  include Rack::Test::Methods

  def app
    TurnstileTestApp
  end

  it "adds the view helpers, with the CSP nonce on every script" do
    get "/signups/new"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include(%(data-sitekey="1x00000000000000000000AA" data-theme="dark"))
    expect(last_response.body).to include(%(<button type="submit">Go</button>))
    expect(last_response.body.scan("<script").size).to eq(4)
    expect(last_response.body.scan(%(nonce="rails-nonce")).size).to eq(4)
    expect(last_response.body).not_to include("&lt;script")
  end

  it "verifies the token in the controller" do
    request = stub_siteverify(success: true, action: "signup").with(body: hash_including("response" => "token"))

    post "/signups", "cf-turnstile-response" => "token"

    expect(last_response.body).to eq("verified")
    expect(request).to have_been_requested
  end

  it "fails with a translated flash message when the token is missing" do
    post "/signups", { "cf-turnstile-response" => "" }, "HTTP_ACCEPT" => "text/html"

    expect(last_response.status).to eq(422)
    expect(last_response.body).to eq(I18n.t("turnstile.errors.verification_failed"))
  end

  it "loads the gem's locales" do
    expect(I18n.t("turnstile.errors.verification_failed", locale: :fr)).to match(/La vérification Turnstile/)
  end

  it "skips verification in the test environment by default" do
    Turnstile.configuration.default_env = "test"

    post "/signups"

    expect(last_response.body).to eq("verified")
  end
end
