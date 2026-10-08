# frozen_string_literal: true

RSpec.describe Turnstile::Testing do
  it "stubs successful verifications without a request" do
    described_class.success!("hostname" => "example.com")

    result = Turnstile.verify(nil)

    expect(result.success?).to be(true)
    expect(result.hostname).to eq("example.com")
    expect(a_request(:post, VERIFY_URL)).not_to have_been_made
  end

  it "stubs failed verifications" do
    described_class.failure!("timeout-or-duplicate")

    expect(Turnstile.verify("token").error_codes).to eq(["timeout-or-duplicate"])
  end

  it "resets" do
    described_class.failure!
    described_class.reset!

    expect(Turnstile.stubbed_response).to be_nil
  end

  it "restores the previous state after the block forms" do
    described_class.with_failure do
      expect(Turnstile.verify("token").success?).to be(false)
      described_class.with_success { expect(Turnstile.verify("token").success?).to be(true) }
      expect(Turnstile.verify("token").success?).to be(false)
    end

    expect(Turnstile.stubbed_response).to be_nil
  end
end
