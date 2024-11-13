module Arb
  module Cli
    class Runner
      SolutionNotFoundError = Class.new(StandardError)
      SolutionArgumentError = Class.new(StandardError)

      def self.run_part(year:, day:, part:, variant: nil, correct_answer:)
        answer = nil
        input_file = File.new(Files::Input.path(year:, day:))
        solution = solution_instance(year:, day:)

        normal_method_name = "part_#{part}"
        variant_method_name = "#{normal_method_name}_#{variant}"

        begin
          if variant && solution.respond_to?(variant_method_name)
            run_time = Benchmark.realtime {
              answer = solution.send(variant_method_name, input_file)
            }
            variant_note = " (variant `#{PASTEL.blue.bold(variant)}`)"
          elsif solution.respond_to?(normal_method_name)
            run_time = Benchmark.realtime {
              answer = solution.send(normal_method_name, input_file)
            }
          else
            puts PASTEL.red("🤔 The method #{PASTEL.bold("Year#{year}::Day#{day}##{normal_method_name}")} doesn't exist.")
          end
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
          puts "(obtained in #{run_time.round(10)} seconds)"
        end

        puts

        answer
      end

      private_class_method def self.solution_instance(year:, day:)
        require "#{Dir.pwd}/src/#{year}/#{day}"

        Module
          .const_get("Year#{year}")
          .const_get("Day#{day}")
          .new
      rescue NameError
        raise SolutionNotFoundError
      end
    end
  end
end
