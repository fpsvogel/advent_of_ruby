module Arb
  module Cli
    # @param year [String, Integer]
    # @param day [String, Integer]
    # @param options [Hash] see `method_option`s above ArbApp#run_day.
    def self.run(year:, day:, options:)
      WorkingDirectory.prepare!

      if options[:spec] && (options[:one] || options[:two])
        raise InputError, "Don't use --spec (-s) with --one (-o) or --two (-t)"
      end

      year, day = YearDayValidator.validate_year_and_day(year:, day:, default_to_untracked_or_last_committed: true)

      if Git.uncommitted_puzzles.empty? && !Git.last_committed_puzzle(year:)
        bootstrap(year:, day:)
        return
      end

      instructions_path = Files::Instructions.download(year, day, notify_exists: false, overwrite: false)
      instructions = File.read(instructions_path)
      correct_answer_1, correct_answer_2 = instructions.scan(/Your puzzle answer was `([^`]+)`./).flatten
      skip_count = 0

      if options[:spec]
        run_specs_only(year, day)
        return
      elsif !(options[:one] || options[:two])
        specs_passed, skip_count = run_specs_before_real(year, day)
        return unless specs_passed
        puts "👍 Specs passed!"
        if skip_count > 1 || (skip_count == 1 && correct_answer_1)
          puts PASTEL.yellow.bold("🤐 #{skip_count} skipped, however")
        end
        puts "\n"
      end

      Files::Input.download(year, day, notify_exists: false)
      answer_1, answer_2 = nil, nil

      begin
        if options[:one] || (!options[:two] && ((correct_answer_1.nil? && skip_count <= 1) || correct_answer_2))
          answer_1 = Runner.run_part(year:, day:, part: "1", variant: options[:variant], correct_answer: correct_answer_1)
        end
        if options[:two] || (!options[:one] && ((correct_answer_1 && !correct_answer_2 && skip_count.zero?) || correct_answer_2))
          answer_2 = Runner.run_part(year:, day:, part: "2", variant: options[:variant],correct_answer: correct_answer_2)
        end
      rescue Runner::SolutionNotFoundError
        puts PASTEL.red("Solution class not found. Make sure this class exists: #{PASTEL.bold("Year#{year}::Day#{day}")}")
      rescue Runner::SolutionArgumentError
        puts PASTEL.red("ArgumentError when running your solution. Make sure every method has a one parameter (the input file).")
      rescue Runner::SolutionArgumentError
      end

      return unless answer_1 || answer_2

      if correct_answer_2
        puts "🙌 You've already submitted the answers to both parts.\n"

        if Git.commit_count <= 1
          puts "When you're done with this puzzle, run " \
            "`#{PASTEL.blue.bold("arb commit")}` (or `arb c`) commit your solution to Git.\n"
        end

        return
      elsif options[:one] && correct_answer_1
        puts "🙌 You've already submitted the answer to this part.\n\n"
        return
      end

      puts "Submit solution? (Y/n)"
      print PASTEL.green("> ")
      submit = STDIN.gets.strip.downcase

      if submit == "y" || submit == ""
        options_part = options[:one] ? "1" : (options[:two] ? "2" : nil)
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
            puts "Downloaded instructions for Part Two."
            `#{ENV["EDITOR_COMMAND"]} #{instructions_path}`

            spec_path = Files::Spec.create(year, day, notify_exists: false)
            spec = File.read(spec_path)
            spec_without_skips = spec.gsub("  xit ", "  it ")
            File.write(spec_path, spec_without_skips)
          end

          if Git.commit_count <= 1
            puts "\nNow it's time to improve your solution! Be sure to look " \
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
      spec_filename =	File.join("spec", year, "#{day}_spec.rb")

      # Running RSpec from within RSpec causes problems, so in the test environment
      # run RSpec in a subprocess.
      if ENV["TEST_ENV"]
        system "rspec #{spec_filename}"
      else
        RSpec::Core::Runner.run([spec_filename])
      end
    end

    private_class_method def self.run_specs_before_real(year, day)
      spec_filename =	File.join("spec", year, "#{day}_spec.rb")

      # Running RSpec from within RSpec causes problems, so in the test environment
      # run RSpec in a subprocess.
      if ENV["TEST_ENV"]
        stdout, _status = Open3.capture2("rspec #{spec_filename} --color --tty")
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
