require_relative "lib/arb/version"

Gem::Specification.new do |spec|
  spec.name          = "advent_of_ruby"
  spec.version       = Arb::VERSION
  spec.authors       = ["Felipe Vogel"]
  spec.email         = ["fps.vogel@gmail.com"]

  spec.summary       = "CLI for Advent of Code in Ruby, via the `arb` command."
  spec.homepage      = "https://github.com/fpsvogel/advent_of_ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = "~> #{File.read(".ruby-version").strip}"

  spec.add_runtime_dependency "benchmark", "~> 0.4"
  spec.add_runtime_dependency "debug", "~> 1.0"
  spec.add_runtime_dependency "dotenv", "~> 3.0"
  spec.add_runtime_dependency "faraday", "~> 2.0"
  spec.add_runtime_dependency "faraday-retry", "~> 2.0"
  spec.add_runtime_dependency "pastel", "~> 0.8"
  spec.add_runtime_dependency "redcarpet", "~> 3.0"
  spec.add_runtime_dependency "reverse_markdown", "~> 2.0"
  spec.add_runtime_dependency "rspec", "~> 3.0"
  spec.add_runtime_dependency "thor", "~> 1.0"
  spec.add_runtime_dependency "vcr", "~> 6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["source_code_uri"] = "https://github.com/fpsvogel/advent_of_ruby"
  spec.metadata["changelog_uri"] = "https://github.com/fpsvogel/avent_of_ruby/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*.rb"]
  spec.bindir = "bin"
  spec.executables << "arb"
  spec.require_paths = ["lib"]
end
