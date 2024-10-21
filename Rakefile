require "bundler/gem_tasks"
require_relative "lib/arb/version"
require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

task default: :install

gem_name = "advent_of_ruby"

task :build do
  `gem build #{gem_name}.gemspec`
end

task :install => :build do
  `gem install #{gem_name}-#{Arb::VERSION}.gem`
  `rm -rf pkg`
  `rm *.gem`
end

task :publish => :build do
  `gem push #{gem_name}-#{Arb::VERSION}.gem`
  `rm -rf pkg`
  `rm *.gem`
end
