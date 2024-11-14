module Arb
  module Cli
    class Runner
      SolutionNotFoundError = Class.new(StandardError)
      SolutionArgumentError = Class.new(StandardError)

      def self.run_part(year:, day:, part:, correct_answer:)
        solution_class = solution_class(year:, day:)
        base_method_name = "part_#{part}"
        variant_method_names = solution_class
            .instance_methods(false)
            .filter { _1.to_s.start_with?(base_method_name)}
            .sort

        if variant_method_names.empty?
          puts PASTEL.red("🤔 Couldn't find the method #{PASTEL.bold("Year#{year}::Day#{day}##{base_method_name}")}.")
          return
        end

        answers = []

        variant_method_names.each do |variant_method_name|
          solution = solution_class.new
          input_file = File.new(Files::Input.path(year:, day:))
          answer = nil

          begin
            run_time = Benchmark.realtime do
              answer = solution.send(variant_method_name, input_file)
            end
            variant = variant_method_name.to_s.delete_prefix(base_method_name).delete_prefix("_")
            variant_note = " `#{PASTEL.blue.bold(variant)}`" unless variant.empty?
          rescue ArgumentError
            raise SolutionArgumentError
          end

          part_name = "#{year}##{day}.#{part}#{variant_note}"

          if answer
            puts "Result for #{part_name}:"

            if correct_answer
              if answer.to_s == correct_answer
                puts PASTEL.green.bold("✅ #{answer}")
              else
                puts PASTEL.red.bold("❌ #{answer} -- should be #{correct_answer}")
              end
            else
              puts PASTEL.bright_white.bold(answer)
            end
          else
            puts "❌ No result for #{part_name}"
          end

          if answer && run_time
            if variant_method_names.count > 1
              puts "(obtained in #{PASTEL.cyan("%.6f" % run_time)} seconds)"
            else
              puts "(obtained in #{"%.6f" % run_time} seconds)"
            end
          end

          answers << answer

          puts
        end

        answers
      end

      private_class_method def self.solution_class(year:, day:)
        require "#{Dir.pwd}/src/#{year}/#{day}"

        Module
          .const_get("Year#{year}")
          .const_get("Day#{day}")
      rescue NameError
        raise SolutionNotFoundError
      end
    end
  end
end
