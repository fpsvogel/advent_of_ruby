module Formatters
  module RuboCop
    # Formats newly created files using RuboCop if it is bundled at the top
    # level (i.e. as `gem "rubocop"` in the Gemfile) or if a RuboCop config file
    # is present. Does nothing if RuboCop isn't bundled or is just a dependency
    # (e.g. of Standard), and if there is no RuboCop config file.
    def self.format(file_path)
      require "bundler"
      require "rubocop"
      return unless rubocop_bundled_at_top_level? || rubocop_config_exists?

      ::RuboCop::CLI.new.run(["-A", file_path, "--out", File::NULL])
    rescue LoadError
      # Do nothing if Bundler is not installed, or if RuboCop is bundled but not
      # actually installed.
    end

    private_class_method def self.rubocop_bundled_at_top_level?
      Bundler.definition.dependencies.any? { it.name == "rubocop" }
    rescue Bundler::GemfileNotFound
      false
    end

    # A shorter approach would be simply `File.exist?(".rubocop.yml")`, but
    # the approach below avoids directly reading a file.
    private_class_method def self.rubocop_config_exists?
      config_path = ::RuboCop::ConfigFinder.find_config_path(Dir.pwd)
      config_path && !config_path.end_with?("config/default.yml")
    end
  end
end
