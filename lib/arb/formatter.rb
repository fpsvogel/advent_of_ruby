begin
  gem "rubocop"
  require "rubocop"
rescue LoadError
  # If RuboCop isn't available, no formatting will be done
end

module Formatter
  class << self
    def format(file_path)
      return unless rubocop_loaded?

      RuboCop::CLI.new.run(["-A", file_path, "--out", File::NULL])
    end

    private

    def rubocop_loaded?
      defined?(RuboCop)
    end
  end
end
