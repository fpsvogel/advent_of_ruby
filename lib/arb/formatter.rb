module Formatter
  def self.format(file_path)
    return unless rubocop_bundled_at_top_level?

    begin
      require "rubocop"
      RuboCop::CLI.new.run(["-A", file_path, "--out", File::NULL])
    rescue LoadError
      # Do nothing if RuboCop is bundled but not actually installed.
    end
  end

  # Check if RuboCop is bundled at the top level, i.e. as `gem "rubocop"` in the
  # Gemfile and not merely as a dependency of another gem.
  private_class_method def self.rubocop_bundled_at_top_level?
    require "bundler"
    Bundler.definition.dependencies.any? { it.name == "rubocop" }
  rescue LoadError, Bundler::GemfileNotFound
    false
  end
end
