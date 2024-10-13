require "benchmark"
require "date"
require "debug"
require "dotenv"
require "httparty"
require "pastel"
require "reverse_markdown"
require "rspec/core"

class AppError < StandardError; end
class InputError < AppError; end
class ConfigError < AppError; end

PASTEL = Pastel.new

Dir[File.join(__dir__, "**", "*.rb")].each do |file|
  require file
end

solution_files = File.join(Dir.pwd, "src", "**", "*.rb")
Dir[solution_files].each do |file|
  require file
end

module Arb
  class Cli
    # @param year [String]
    # @param day [String]
    def self.bootstrap(year, day)
      Arb::WorkingDirectory.prepare!

      year, day = validate_year_and_day(year, day)

      git_commit

      input_path = Arb::InputFile.download(year, day)
      instructions_path = Arb::InstructionsFile.download(year, day)
      source_path = Arb::SourceFile.create(year, day)
      spec_path = Arb::SpecFile.create(year, day)
      others_1_path, others_2_path = Arb::OtherSolutionsFiles.download(year, day)

      puts "🤘 Bootstrapped #{year}##{day}\n\n"

      # Open the new files.
      `#{ENV["EDITOR_COMMAND"]} #{others_1_path}`
      `#{ENV["EDITOR_COMMAND"]} #{others_2_path}`
      `#{ENV["EDITOR_COMMAND"]} #{input_path}`
      `#{ENV["EDITOR_COMMAND"]} #{source_path}`
      `#{ENV["EDITOR_COMMAND"]} #{spec_path}`
      `#{ENV["EDITOR_COMMAND"]} #{instructions_path}`

      last_committed_solution = `git log -n 1 --diff-filter=A --name-only --pretty=format: #{File.join("src", year || "")}`.lines.last
      if !last_committed_solution
        puts "Now fill in the spec for Part One with an example from the instructions, " \
          "then run it with `#{PASTEL.blue.bold("arb run")}` (or just `arb`) as " \
          "you implement the solution. When the spec passes, your solution will " \
          "be run with the real input and you'll be prompted to submit your solution.\n"
      end
    rescue AppError => e
      puts Pastel.new.red(e.message)
    end

    # @param year [String]
    # @param day [String]
    # @param options [Thor::CoreExt::HashWithIndifferentAccess]
    def self.run_day(year, day, options)
      Arb::WorkingDirectory.prepare!

      if options.spec? && (options.real_part_1? || options.real_part_2?)
        raise InputError, "Don't use --spec (-s) with --real_part_1 (-o) or --real_part_2 (-t)"
      end

      year, day = validate_year_and_day(year, day, default_untracked_or_done: true)

      untracked_solutions = `git status -su | grep "^?? #{File.join("src", year || "")}"`
      last_committed_solution = `git log -n 1 --diff-filter=A --name-only --pretty=format: #{File.join("src", year || "")}`.lines.last
      if untracked_solutions.empty? && !last_committed_solution
        bootstrap(year, day)
        return
      end

      solution = Arb::Runner.load_solution(year, day)
      input_path = Arb::InputFile.download(year, day, notify_exists: false)
      answer_1, answer_2 = nil, nil

      instructions_path = Arb::InstructionsFile.download(year, day, notify_exists: false, overwrite: false)
      instructions = File.read(instructions_path)
      correct_answer_1, correct_answer_2 = instructions.scan(/Your puzzle answer was `([^`]+)`./).flatten
      skip_count = 0

      if options.spec?
        run_specs_only(year, day)
        return
      elsif !(options.real_part_1? || options.real_part_2?)
        specs_passed, skip_count = run_specs_before_real(year, day)
        return unless specs_passed
        puts "👍 Specs passed!"
        if skip_count > 1 || (skip_count == 1 && correct_answer_1)
          puts PASTEL.yellow.bold("🤐 #{skip_count} skipped, however")
        end
        puts "\n"
      end

      if options.real_part_1? || (!options.real_part_2? && ((correct_answer_1.nil? && skip_count <= 1) || correct_answer_2))
        answer_1 = Arb::Runner.run_part("#{year}##{day}.1", correct_answer_1) do
          solution.part_1(File.new(input_path))
        end
      end
      if options.real_part_2? || (!options.real_part_1? && ((correct_answer_1 && !correct_answer_2 && skip_count.zero?) || correct_answer_2))
        answer_2 = Arb::Runner.run_part("#{year}##{day}.2", correct_answer_2) do
          solution.part_2(File.new(input_path))
        end
      end

      return unless answer_1 || answer_2

      if correct_answer_2
        puts "🙌 You've already submitted the answers to both parts.\n\n"

        last_committed_solution = `git log -n 1 --diff-filter=A --name-only --pretty=format: #{File.join("src", year || "")}`.lines.last
        if !last_committed_solution
          puts "\nWhen you're done with this puzzle, run " \
            "`#{PASTEL.blue.bold("arb bootstrap")}` (or `arb b`) to prep the next puzzle.\n"
        end

        return
      elsif options.real_part_1? && correct_answer_1
        puts "🙌 You've already submitted the answer to this part.\n\n"
        return
      end

      puts "Submit solution? (Y/n)"
      print PASTEL.green("> ")
      submit = STDIN.gets.strip.downcase

      if submit == "y" || submit == ""
        options_part = options.real_part_1? ? "1" : (options.real_part_2? ? "2" : nil)
        inferred_part = correct_answer_1.nil? ? "1" : "2"
        aoc_api = Arb::AocApi.new(Arb::ENV["AOC_COOKIE"])

        response = aoc_api.submit(year, day, options_part || inferred_part, answer_2 || answer_1)
        message = response.match(/(?<=<article>).+(?=<\/article>)/m).to_s.strip
        markdown_message = ReverseMarkdown.convert(message)
        short_message = markdown_message
          .sub(/\n\n.+/m, "")
          .sub(/ \[\[.+/, "")

        if short_message.start_with?("That's the right answer!")
          puts "⭐ #{short_message}\n\n"

          # TODO don't re-download if the instructions file already contains the next part
          instructions_path = Arb::InstructionsFile.download(year, day, overwrite: true)

          if (options_part || inferred_part) == "1"
            puts "Downloaded instructions for Part Two.\n\n"
            `#{ENV["EDITOR_COMMAND"]} #{instructions_path}`

            spec_path = Arb::SpecFile.create(year, day, notify_exists: false)
            spec = File.read(spec_path)
            spec_without_skips = spec.gsub("  xit ", "  it ")
            File.write(spec_path, spec_without_skips)
          end

          last_committed_solution = `git log -n 1 --diff-filter=A --name-only --pretty=format: #{File.join("src", year || "")}`.lines.last
          if !last_committed_solution
            puts "\n\nNow it's time to improve your solution! Be sure to look " \
              "at other people's solutions (in the \"others\" directory). When " \
              "you're done, run `#{PASTEL.blue.bold("arb bootstrap")}` (or `arb b`) " \
              "to prep the next puzzle.\n"
          end
        else
          puts "❌ #{short_message}"
        end
      end
    rescue AppError => e
      puts PASTEL.red(e.message)
    end

    def self.progress
      Arb::WorkingDirectory.prepare!

      past_year_count = 25 * (Date.today.year - 1 - 2015)
      this_year_count = (Date.today.month == 12 ? Date.today.day : 0).clamp(..25)
      total_count = past_year_count + this_year_count

      my_counts_by_year = `git ls-files src/`
        .split("\n")
        .select { |path| File.basename(path).match?(/\d\d\.rb/) }
        .group_by { |path| File.basename(File.dirname(path)) }
        .transform_values(&:count)
      my_total_count = my_counts_by_year.values.sum

      total_percent = (my_total_count.to_f / total_count * 100).round(1)
      total_percent == total_percent.to_i ? total_percent.to_i : total_percent

      puts "You have completed:\n\n"
      puts PASTEL.bold "#{PASTEL.blue("All:")}\t#{total_percent}% \t#{my_total_count}/#{total_count} puzzles\n"

      my_counts_by_year.each do |year, my_count|
        if year.to_i == Date.today.year
          year_count = this_year_count
        else
          year_count = 25
        end

        year_percent = (my_count.to_f / year_count * 100).round

        puts "#{PASTEL.blue(year + ":")}\t#{year_percent}%\t#{my_count}/#{year_count}"
      end
    end

    def self.git_commit
      Arb::WorkingDirectory.prepare!

      # TODO extract this etc. into a Git interface
      changes = `git status -su | grep -e "^?? src" -e "^?? spec"`
      files_added = !changes.empty?
      if changes.empty?
        changes = `git status -su | grep -e "^ M src" -e "^ M spec"`
      end
      change_year, change_day = nil, nil
      unless changes.empty?
        match = changes.match(/(?<year>\d{4})\/(?<day>\d\d)(?:_spec)?.rb$/)
        change_year, change_day = match[:year], match[:day]
        `git add -A`
        `git commit -m "#{files_added ? "Solve" : "Improve"} #{change_year}##{change_day}"`

        if files_added && change_day == "25"
          puts "\n🎉 You've finished #{change_year}!\n\n"
        end
      end
    end

    private_class_method def self.run_specs_only(year, day)
      padded_day = day.rjust(2, "0")
      spec_filename =	[File.join("spec", year, "#{padded_day}_spec.rb")]

      RSpec::Core::Runner.run(spec_filename)
    end

    private_class_method def self.run_specs_before_real(year, day)
      padded_day = day.rjust(2, "0")
      spec_filename =	[File.join("spec", year, "#{padded_day}_spec.rb")]

      out = StringIO.new
      RSpec::Core::Runner.run(spec_filename, $stderr, out)

      if out.string.match?(/Failures:/)
        RSpec.reset
        RSpec::Core::Runner.run(spec_filename)

        [false, nil]
      else
        [true, out.string.scan("skipped with xit").count]
      end
    end

    private_class_method def self.validate_year_and_day(year, day, default_untracked_or_done: false)
      # The first two digits of the year may be omitted.
      year = "20#{year}" if year && year.length == 2

      if day && !year
        raise InputError, "If you specify the day, specify the year also."
      elsif !day
        if default_untracked_or_done
          untracked_solutions = `git status -su | grep "^?? #{File.join("src", year || "")}"`

          unless untracked_solutions.empty?
            match = untracked_solutions.match(/(?<year>\d{4})\/(?<day>\d\d).rb$/)
            year, day = match[:year], match[:day]
          end
        end

        if !default_untracked_or_done || untracked_solutions.empty?
          if year && !Dir.exist?(File.join("src", year))
            Dir.mkdir(File.join("src", year))
            day = "1"
          else
            last_committed_solution = `git log -n 1 --diff-filter=A --name-only --pretty=format: #{File.join("src", year || "")}`.lines.last

            if last_committed_solution
              match = last_committed_solution.match(/(?<year>\d{4})\/(?<day>\d\d).rb$/)

              year, day = match[:year], match[:day]
              if !default_untracked_or_done
                if day == "25"
                  day = :end
                else
                  day = day.next
                end
              end
            end

            if !last_committed_solution || day == :end
              # TODO refactor to combine this with #progress
              default_year = "2015"
              default_day = "1"
              bootstrap_year_prompt = nil

              committed_solution_files = `git log --diff-filter=A --name-only --pretty=format: src`
              if committed_solution_files.empty?
                bootstrap_year_prompt = "What year's puzzles do you want to start with? (default: #{default_year})"
              else
                previous_days = (2015..Date.today.year - 1).map(&:to_s).map { [_1, (1..25).map { |day| day.to_s.rjust(2, "0") }] }.to_h
                previous_days.merge!(Date.today.year.to_s => (1..Date.today.day).map { |day| day.to_s.rjust(2, "0") }) if Date.today.month == 12

                committed_days = committed_solution_files
                  .split("\n")
                  .map {
                    match = _1.match(/(?<year>\d{4})\/(?<day>\d\d).rb$/)
                    year, day = match[:year], match[:day]
                    [year, day]
                  }
                  .group_by(&:first)
                  .transform_values { _1.map(&:last) }

                default_year, default_day = previous_days
                  .map { |k, v| [k, v - (committed_days[k] || [])] }
                  .to_h
                  .then {
                    [_1.keys.first, _1.values.first.first]
                  }
                default_day.delete_prefix!("0")

                puts "You've recently finished #{year}. Yay!"
                bootstrap_year_prompt = "What year do you want to bootstrap next? (default: #{default_year} [at Day #{default_day}])"
              end

              loop do
                puts bootstrap_year_prompt
                print PASTEL.green("> ")
                year_input = STDIN.gets.strip
                puts
                if year_input.strip.empty?
                  year = default_year
                  day = default_day
                else
                  year = year_input.strip.match(/\A\d{4}\z/)&.to_s
                  day = "1"
                end
                break if year
              end
            end
          end
        end
      end

      year = Integer(year, exception: false) || (raise InputError, "Year must be a number.")
      day = Integer(day, exception: false) || (raise InputError, "Day must be a number.")

      unless year.between?(2015, Date.today.year)
        raise InputError, "Year must be between 2015 and this year."
      end
      unless day.between?(1, 25) && Date.new(year, 12, day) <= Date.today
        raise InputError, "Day must be between 1 and 25, and <= today."
      end

      [year.to_s, day.to_s]
    end
  end
end
