# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |task|
  task.exclude_pattern = "spec/rails/**/*_spec.rb"
end

namespace :spec do
  # Runs in its own process so the main suite covers the gem without Rails loaded.
  RSpec::Core::RakeTask.new(:rails) do |task|
    task.pattern = "spec/rails/**/*_spec.rb"
  end
end

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec spec:rails rubocop]
