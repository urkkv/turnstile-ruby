# frozen_string_literal: true

RSpec.describe Turnstile::Adapters::ControllerMethods do
  let(:request_class) do
    Struct.new(:remote_ip) do
      def format
        :html
      end
    end
  end

  let(:controller_class) do
    Class.new do
      include Turnstile::Adapters::ControllerMethods

      attr_reader :params, :request, :flash

      def initialize(params, request)
        @params = params
        @request = request
        @flash = {}
      end

      public :verify_turnstile, :verify_turnstile!, :turnstile_reply
    end
  end

  let(:model) do
    Class.new do
      def errors
        @errors ||= Class.new do
          attr_reader :added

          def add(attribute, message)
            (@added ||= []) << [attribute, message]
          end
        end.new
      end
    end.new
  end

  let(:params) { { "cf-turnstile-response" => "token" } }
  let(:controller) { controller_class.new(params, request_class.new("1.2.3.4")) }

  it "returns true for a valid token and sends the remote ip" do
    request = stub_siteverify(success: true).with(body: hash_including("response" => "token", "remoteip" => "1.2.3.4"))

    expect(controller.verify_turnstile).to be(true)
    expect(request).to have_been_requested
    expect(controller.turnstile_reply).to eq("success" => true)
  end

  it "can leave the remote ip out" do
    stub_siteverify(success: true)

    controller.verify_turnstile(skip_remote_ip: true)

    expect(a_request(:post, VERIFY_URL).with { |req| !req.body.include?("remoteip") }).to have_been_made
  end

  it "falls back to request.ip outside Rails" do
    stub_siteverify(success: true)
    rack_request = Struct.new(:ip).new("5.6.7.8")

    controller_class.new(params, rack_request).verify_turnstile

    expect(a_request(:post, VERIFY_URL).with(body: hash_including("remoteip" => "5.6.7.8"))).to have_been_made
  end

  it "returns false and sets the flash for a rejected token" do
    stub_siteverify(success: false, "error-codes": ["invalid-input-response"])

    expect(controller.verify_turnstile).to be(false)
    expect(controller.flash[:turnstile_error]).to match(/verification failed/)
    expect(controller.turnstile_reply["error-codes"]).to eq(["invalid-input-response"])
  end

  it "clears a previous flash error on success" do
    stub_siteverify(success: true)
    controller.flash[:turnstile_error] = "old"

    controller.verify_turnstile

    expect(controller.flash).to be_empty
  end

  it "returns false instead of raising when the token is missing" do
    controller = controller_class.new({}, request_class.new("1.2.3.4"))

    expect(controller.verify_turnstile).to be(false)
    expect(controller.turnstile_reply["error-codes"]).to eq(["missing-input-response"])
    expect(a_request(:post, VERIFY_URL)).not_to have_been_made
  end

  it "adds the error to the model instead of the flash" do
    stub_siteverify(success: false)

    expect(controller.verify_turnstile(model: model, attribute: :captcha, message: "Nope")).to be(false)
    expect(model.errors.added).to eq([[:captcha, "Nope"]])
    expect(controller.flash).to be_empty
  end

  it "accepts the model as the only argument" do
    stub_siteverify(success: false)

    controller.verify_turnstile(model)

    expect(model.errors.added.first.first).to eq(:base)
  end

  it "falls back to the flash when the model has no errors, such as a class" do
    stub_siteverify(success: false)

    expect(controller.verify_turnstile(model: Class.new)).to be(false)
    expect(controller.flash[:turnstile_error]).to match(/verification failed/)
  end

  it "verifies an explicit response token" do
    request = stub_siteverify(success: true).with(body: hash_including("response" => "explicit"))

    controller.verify_turnstile(response: "explicit")

    expect(request).to have_been_requested
  end

  it "skips verification in skipped environments" do
    expect(controller.verify_turnstile(env: "test")).to be(true)
    expect(a_request(:post, VERIFY_URL)).not_to have_been_made
  end

  it "honours a Turnstile::Testing stub even in skipped environments" do
    Turnstile::Testing.failure!

    expect(controller.verify_turnstile(env: "test")).to be(false)
  end

  context "when Cloudflare is unreachable" do
    it "fails gracefully on timeouts" do
      stub_request(:post, VERIFY_URL).to_timeout

      expect(controller.verify_turnstile).to be(false)
      expect(controller.flash[:turnstile_error]).to match(/failed to validate/)
    end

    it "fails gracefully on a non-JSON reply" do
      stub_siteverify("<html>502</html>", status: 502)

      expect(controller.verify_turnstile).to be(false)
      expect(controller.flash[:turnstile_error]).to match(/failed to validate/)
    end

    it "raises when graceful handling is off" do
      Turnstile.configuration.handle_timeouts_gracefully = false
      stub_request(:post, VERIFY_URL).to_timeout

      expect { controller.verify_turnstile }.to raise_error(Turnstile::TurnstileError, "Turnstile unreachable.")
    end
  end

  it "wraps unexpected errors in TurnstileError" do
    stub_request(:post, VERIFY_URL).to_raise(SocketError.new("no route"))

    expect { controller.verify_turnstile }.to raise_error(Turnstile::TurnstileError, /no route/)
  end

  describe "#verify_turnstile!" do
    it "returns true on success" do
      stub_siteverify(success: true)

      expect(controller.verify_turnstile!).to be(true)
    end

    it "raises VerifyError with the error codes on failure" do
      stub_siteverify(success: false, "error-codes": ["timeout-or-duplicate"])

      expect { controller.verify_turnstile! }.to raise_error(Turnstile::VerifyError, /timeout-or-duplicate/)
    end
  end
end
