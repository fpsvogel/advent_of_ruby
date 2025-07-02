module Formatters
  module RuboCop
    # Formats newly created files using RuboCop if it is bundled at the top
    # level, i.e. as `gem "rubocop"` in the Gemfile. Does nothing if RuboCop
    # isn't bundled or is just a dependency, e.g. of Standard.
    def self.format(file_path)
      return unless rubocop_bundled_at_top_level?

      begin
        require "rubocop"
        RuboCop::CLI.new.run(["-A", file_path, "--out", File::NULL])
      rescue LoadError
        # Do nothing if RuboCop is bundled but not actually installed.
      end
    end

    private_class_method def self.rubocop_bundled_at_top_level?
      require "bundler"
      Bundler.definition.dependencies.any? { it.name == "rubocop" }
    rescue LoadError, Bundler::GemfileNotFound
      false
    end
  end
end
