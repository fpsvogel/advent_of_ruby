module Arb
  module Cli
    class WorkingDirectory
      FILES = {
        gitignore: <<~FILE,
          input/**/*
          instructions/**/*
          others/**/*
          .env

        FILE
        ruby_version: "3.3.0\n",
        gemfile: <<~FILE,
          source "https://rubygems.org"
          ruby file: ".ruby-version"

        FILE
        spec_helper_addition: <<~FILE
          require "debug"

          Dir[File.join(__dir__, "..", "src", "**", "*.rb")].each do |file|
            require file
          end


        FILE
      }

      def self.env_keys = ["EDITOR_COMMAND", "AOC_COOKIE"]
      def self.default_editor_command = "code"

      def self.prepare!
        files_created = []

        existing_dotenv = Dotenv.parse(".env")
        unless env_keys.all? { existing_dotenv.has_key?(_1) }
          create_dotenv!(existing_dotenv)
          files_created << :dotenv
        end
        Dotenv.load
        Dotenv.require_keys(*env_keys)

        files_created += create_other_files!

        if files_created.any?
          puts "✅ Initial files created and committed to a new Git repository.\n\n"
        end
      end

      def self.refresh_aoc_cookie!
        print "Uh oh, your Advent of Code session cookie has expired or was " \
          "incorrectly entered. "
        ENV["AOC_COOKIE"] = input_aoc_cookie
        File.write(".env", generate_dotenv)
      end

      private

      def self.generate_dotenv(new_dotenv)
        new_dotenv.slice(*env_keys).map { |k, v|
          "#{k}=#{v}"
        }.join("\n")
      end

      def self.create_dotenv!(existing_dotenv)
        new_dotenv = existing_dotenv.dup

        puts "🎄 Welcome to Advent of Code in Ruby! 🎄\n\n"
        puts "Let's start with some configuration.\n\n"

        unless existing_dotenv.has_key?("EDITOR_COMMAND")
          puts "What's the shell command to start your editor? (default: #{default_editor_command})"
          print PASTEL.green("> ")
          editor_command = STDIN.gets.strip
          editor_command = default_editor_command if editor_command.empty?
          new_dotenv["EDITOR_COMMAND"] = editor_command
        end

        puts

        unless existing_dotenv.has_key?("AOC_COOKIE")
          new_dotenv["AOC_COOKIE"] = input_aoc_cookie
        end

        File.write(".env", generate_dotenv(new_dotenv))
      end

      def self.input_aoc_cookie
        aoc_cookie = nil

        loop do
          puts "What's your Advent of Code session cookie?"
          puts PASTEL.dark.white("To find it, log in to [Advent of Code](https://adventofcode.com/) and then:")
          puts PASTEL.dark.white("  Firefox: Developer Tools ⇨ Storage tab ⇨ Cookies")
          puts PASTEL.dark.white("  Chrome: Developer Tools ⇨ Application tab ⇨ Cookies")
          print PASTEL.green("> ")

          aoc_cookie = STDIN.gets.strip

          puts

          break unless aoc_cookie.strip.empty?
        end

        aoc_cookie
      end

      def self.create_other_files!
        other_files_created = []

        unless Dir.exist?("src")
          Dir.mkdir("src")
          other_files_created << :src_dir
        end

        unless Dir.exist?("spec")
          Dir.mkdir("spec")
          other_files_created << :spec_dir
        end

        unless File.exist?(".gitignore")
          File.write(".gitignore", FILES.fetch(:gitignore))
          other_files_created << :gitignore
        end

        unless File.exist?(".ruby-version")
          File.write(".ruby-version", FILES.fetch(:ruby_version))
          other_files_created << :ruby_version
        end

        unless File.exist?("Gemfile")
          File.write("Gemfile", FILES.fetch(:gemfile))
          other_files_created << :gemfile
        end

        spec_helper_path = File.join("spec", "spec_helper.rb")
        unless File.exist?(".rspec") && File.exist?(spec_helper_path)
          rspec_init_output = `rspec --init`
          unless rspec_init_output.match?(/exist\s+spec.spec_helper.rb/)
            original_spec_helper = File.read(spec_helper_path)
            File.write(spec_helper_path, FILES.fetch(:spec_helper_addition) + original_spec_helper)
            other_files_created << :spec_helper
          end
          other_files_created << :rspec
        end

        unless Git.repo_exists?
          Git.init!
          Git.commit_all!(message: "Initial commit")
          other_files_created << :git
        end

        other_files_created
      end
    end
  end
end
