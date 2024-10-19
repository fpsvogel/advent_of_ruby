module Arb
  module Cli
    class Runner
      def self.load_solution(year, day)
        padded_day = day.rjust(2, "0")
        Module.const_get("Year#{year}").const_get("Day#{padded_day}").new
      rescue NameError
        puts "There is no solution for this puzzle"
      end

      def self.run_part(part_name, correct_answer)
        answer = nil
        t = Benchmark.realtime do
          answer = yield
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
        end

        if answer
          puts "(obtained in #{t.round(10)} seconds)"
        end

        puts

        answer
      end
    end
  end
end
