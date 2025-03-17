module Arb
  module Cli
    class WorkingDirectory
      FILES = {
        ".gitignore" => <<~FILE,
          input/**/*
          instructions/**/*
          others/**/*
          .env
        FILE
        ".ruby-version" => "3.3.0\n",
        "Gemfile" => <<~FILE,
          source "https://rubygems.org"
          ruby file: ".ruby-version"
        FILE
        File.join("spec", "spec_helper.rb") => <<~FILE
          require "debug"

          Dir[File.join(__dir__, "..", "src", "**", "*.rb")].each do |file|
            require file
          end


        FILE
      }

      ENV_KEYS = ["EDITOR_COMMAND", "AOC_COOKIE"]
      DEFAULT_EDITOR_COMMAND = "code"

      def self.prepare!
        files_created = []

        existing_dotenv = Dotenv.parse(".env")
        unless ENV_KEYS.all? { existing_dotenv.has_key?(it) }
          create_dotenv!(existing_dotenv)
          files_created << :dotenv
        end
        Dotenv.load
        Dotenv.require_keys(*ENV_KEYS)

        files_created += create_other_files!

        if files_created.any?
          puts "✅ Initial files created and committed to a new Git repository."
          puts
        end
      end

      def self.refresh_aoc_cookie!
        print "Uh oh, your Advent of Code session cookie has expired or was " \
          "incorrectly entered. "
        ENV["AOC_COOKIE"] = input_aoc_cookie
        File.write(".env", generate_dotenv)
      end

      private_class_method def self.generate_dotenv(new_dotenv)
        new_dotenv.slice(*ENV_KEYS).map { |k, v|
          "#{k}=#{v}"
        }.join("\n")
      end

      private_class_method def self.create_dotenv!(existing_dotenv)
        new_dotenv = existing_dotenv.dup

        puts "🎄 Welcome to Advent of Code in Ruby! 🎄"
        puts
        puts "Let's start with some configuration."
        puts

        unless existing_dotenv.has_key?("EDITOR_COMMAND")
          puts "What's the shell command to start your editor? (default: #{DEFAULT_EDITOR_COMMAND})"
          print PASTEL.green("> ")
          editor_command = $stdin.gets.strip
          editor_command = DEFAULT_EDITOR_COMMAND if editor_command.empty?
          new_dotenv["EDITOR_COMMAND"] = editor_command
        end

        puts
        puts

        unless existing_dotenv.has_key?("AOC_COOKIE")
          new_dotenv["AOC_COOKIE"] = input_aoc_cookie
        end

        File.write(".env", generate_dotenv(new_dotenv))
      end

      private_class_method def self.input_aoc_cookie
        aoc_cookie = nil

        loop do
          puts "What's your Advent of Code session cookie?"
          puts PASTEL.dark.white("To find it, log in to [Advent of Code](https://adventofcode.com/) and then:")
          puts PASTEL.dark.white("  Firefox: Developer Tools ⇨ Storage tab ⇨ Cookies")
          puts PASTEL.dark.white("  Chrome: Developer Tools ⇨ Application tab ⇨ Cookies")
          print PASTEL.green("> ")

          aoc_cookie = $stdin.gets.strip

          puts
          puts

          break unless aoc_cookie.strip.empty?
        end

        aoc_cookie
      end

      private_class_method def self.create_other_files!
        other_files_created = []

        unless Dir.exist?("src")
          Dir.mkdir("src")
          other_files_created << "src"
        end

        unless Dir.exist?("spec")
          Dir.mkdir("spec")
          other_files_created << "spec"
        end

        FILES.slice(".gitignore", ".ruby-version", "Gemfile").each do |filename, contents|
          unless File.exist?(filename)
            File.write(filename, contents)
            other_files_created << filename
          end
        end

        spec_helper_path = File.join("spec", "spec_helper.rb")
        unless File.exist?(".rspec") && File.exist?(spec_helper_path)
          rspec_init_output = `rspec --init`
          unless rspec_init_output.match?(/exist\s+spec.spec_helper.rb/)
            original_spec_helper = File.read(spec_helper_path)
            File.write(spec_helper_path, FILES.fetch(spec_helper_path) + original_spec_helper)
            other_files_created << spec_helper_path
          end
          other_files_created << ".rspec"
        end

        unless Git.repo_exists?
          Git.init!
          Git.commit_all!(message: "Initial commit")
          other_files_created << ".git"
        end

        other_files_created
      end
    end
  end
end
