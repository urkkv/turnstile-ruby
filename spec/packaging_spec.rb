# frozen_string_literal: true

RSpec.describe "gem packaging" do
  let(:gemspec) { Gem::Specification.load(File.expand_path("../turnstile-ruby.gemspec", __dir__)) }

  it "ships everything the gem needs at runtime" do
    expect(gemspec.files).to include(
      "lib/turnstile-ruby.rb", "lib/turnstile.rb", "lib/turnstile/helper.js", "lib/turnstile/testing.rb",
      "rails/locales/en.yml", "LICENSE.txt", "README.md", "CHANGELOG.md"
    )
  end

  it "does not ship the demos or specs" do
    expect(gemspec.files.grep(%r{\A(demo|spec)/})).to be_empty
  end

  it "keeps the VERSION file in sync" do
    expect(File.read(File.expand_path("../VERSION", __dir__)).strip).to eq(Turnstile::VERSION)
  end
end
