module Arb
  module Cli
    module Shared
      class WorkingDirectory
        def self.env_keys = ["EDITOR_COMMAND", "AOC_COOKIE"]
        def self.default_editor_command = "code"

        def self.prepare!
          files_created = false

          existing_dotenv = Dotenv.parse(".env")
          unless env_keys.all? { existing_dotenv.has_key?(_1) }
            create_dotenv!(existing_dotenv)
            files_created = true
          end
          Dotenv.load
          Dotenv.require_keys(*env_keys)

          files_created = create_other_files!

          if files_created
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
          other_files_created = false

          if !Dir.exist?("src")
            Dir.mkdir("src")
            other_files_created = true
          end

          if !Dir.exist?("spec")
            Dir.mkdir("spec")
            other_files_created = true
          end

          if !File.exist?(".gitignore")
            File.write(".gitignore", "input/**/*\ninstructions/**/*\nothers/**/*\n.env\n")
            other_files_created = true
          end

          if !File.exist?(".ruby-version")
            File.write(".ruby-version", "3.3.0\n")
            other_files_created = true
          end

          if !File.exist?("Gemfile")
            File.write("Gemfile", "source \"https://rubygems.org\"\n\nruby file: \".ruby-version\"\n\n# Gems required by your solutions:\n")
            other_files_created = true
          end

          spec_helper_path = File.join("spec", "spec_helper.rb")
          if (!File.exist?(".rspec") || !File.exist?(spec_helper_path))
            rspec_init_output = `rspec --init`
            unless rspec_init_output.match?(/exist\s+spec.spec_helper.rb/)
              original_spec_helper = File.read(spec_helper_path)
              spec_helper_addition = "require \"debug\"\n\nDir[File.join(__dir__, \"..\", \"src\", \"**\", \"*.rb\")].each do |file|\n  require file\nend\n\n"
              File.write(spec_helper_path, spec_helper_addition + original_spec_helper)
            end
            other_files_created = true
          end

          git_repo_exists = `git rev-parse --is-inside-work-tree 2> /dev/null`.chomp
          if git_repo_exists != "true"
            `git init`
            `git add .`
            `git commit -m "Initial commit"`
            other_files_created = true
          end

          other_files_created
        end
      end
    end
  end
end
