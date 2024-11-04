module Arb
  module Cli
    # @param year [String, Integer]
    # @param day [String, Integer]
    # @param options [Hash] see `method_option`s above ArbApp#run_day.
    def self.run(year:, day:, options:)
      WorkingDirectory.prepare!

      if options[:spec] && (options[:real_part_1] || options[:real_part_2])
        raise InputError, "Don't use --spec (-s) with --real_part_1 (-o) or --real_part_2 (-t)"
      end

      year, day = YearDayValidator.validate_year_and_day(year:, day:, default_untracked_or_done: true)

      if Git.new_solutions.none? && !Git.last_committed_solution(year:)
        bootstrap(year:, day:)
        return
      end

      solution = Runner.load_solution(year, day)
      input_path = Files::Input.download(year, day, notify_exists: false)
      answer_1, answer_2 = nil, nil

      instructions_path = Files::Instructions.download(year, day, notify_exists: false, overwrite: false)
      instructions = File.read(instructions_path)
      correct_answer_1, correct_answer_2 = instructions.scan(/Your puzzle answer was `([^`]+)`./).flatten
      skip_count = 0

      if options[:spec]
        run_specs_only(year, day)
        return
      elsif !(options[:real_part_1] || options[:real_part_2])
        specs_passed, skip_count = run_specs_before_real(year, day)
        return unless specs_passed
        puts "👍 Specs passed!"
        if skip_count > 1 || (skip_count == 1 && correct_answer_1)
          puts PASTEL.yellow.bold("🤐 #{skip_count} skipped, however")
        end
        puts "\n"
      end

      if options[:real_part_1] || (!options[:real_part_2] && ((correct_answer_1.nil? && skip_count <= 1) || correct_answer_2))
        answer_1 = Runner.run_part("#{year}##{day}.1", correct_answer_1) do
          solution.part_1(File.new(input_path))
        end
      end
      if options[:real_part_2] || (!options[:real_part_1] && ((correct_answer_1 && !correct_answer_2 && skip_count.zero?) || correct_answer_2))
        answer_2 = Runner.run_part("#{year}##{day}.2", correct_answer_2) do
          solution.part_2(File.new(input_path))
        end
      end

      return unless answer_1 || answer_2

      if correct_answer_2
        puts "🙌 You've already submitted the answers to both parts.\n\n"

        if Git.commit_count <= 1
          puts "When you're done with this puzzle, run " \
            "`#{PASTEL.blue.bold("arb commit")}` (or `arb c`) commit your solution to Git.\n"
        end

        return
      elsif options[:real_part_1] && correct_answer_1
        puts "🙌 You've already submitted the answer to this part.\n\n"
        return
      end

      puts "Submit solution? (Y/n)"
      print PASTEL.green("> ")
      submit = STDIN.gets.strip.downcase

      if submit == "y" || submit == ""
        options_part = options[:real_part_1] ? "1" : (options[:real_part_2] ? "2" : nil)
        inferred_part = correct_answer_1.nil? ? "1" : "2"
        aoc_api = Api::Aoc.new(ENV["AOC_COOKIE"])

        response = aoc_api.submit(year, day, options_part || inferred_part, answer_2 || answer_1)
        message = response.match(/(?<=<article>).+(?=<\/article>)/m).to_s.strip
        markdown_message = ReverseMarkdown.convert(message)
        short_message = markdown_message
          .sub(/\n\n.+/m, "")
          .sub(/ \[\[.+/, "")

        if short_message.start_with?("That's the right answer!")
          puts "\n⭐ #{short_message}"

          # TODO don't re-download if the instructions file already contains the next part
          instructions_path = Files::Instructions.download(year, day, overwrite: true)

          if (options_part || inferred_part) == "1"
            puts "Downloaded instructions for Part Two.\n"
            `#{ENV["EDITOR_COMMAND"]} #{instructions_path}`

            spec_path = Files::Spec.create(year, day, notify_exists: false)
            spec = File.read(spec_path)
            spec_without_skips = spec.gsub("  xit ", "  it ")
            File.write(spec_path, spec_without_skips)
          end

          if Git.commit_count <= 1
            puts "\n\nNow it's time to improve your solution! Be sure to look " \
              "at other people's solutions (in the \"others\" directory). When " \
              "you're done, run `#{PASTEL.blue.bold("arb commit")}` (or `arb c`) " \
              "to commit your solution to Git.\n"
          end
        else
          puts "❌ #{short_message}"
        end
      end
    rescue AppError => e
      puts PASTEL.red(e.message)
    end

    private_class_method def self.run_specs_only(year, day)
      padded_day = day.rjust(2, "0")
      spec_filename =	[File.join("spec", year, "#{padded_day}_spec.rb")]

      RSpec::Core::Runner.run(spec_filename)
    end

    private_class_method def self.run_specs_before_real(year, day)
      padded_day = day.rjust(2, "0")
      spec_filename =	File.join("spec", year, "#{padded_day}_spec.rb")

      # Running RSpec from within RSpec causes problems, so in the test environment
      # run RSpec in a subprocess.
      if ENV["TEST_ENV"]
        stdout, _stderr, _status = Open3.capture3("rspec #{spec_filename} --color --tty")
      else
        stdout = StringIO.new

        RSpec.configure do |config|
          config.color = true
          config.tty = true
          config.output_stream = stdout
        end

        RSpec::Core::Runner.run([spec_filename])
        stdout = stdout.string
      end

      if stdout.include? "Failures:"
        puts stdout

        [false, nil]
      elsif stdout.include?("Finished in ") && stdout.include?("0 failures")
        [true, stdout.scan("skipped with xit").count]
      else
        uncolorized_stdout = stdout.gsub(/\e\[\d+m/, "")
        raise uncolorized_stdout
      end
    end
  end
end
