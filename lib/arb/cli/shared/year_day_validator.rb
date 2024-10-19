module Arb
  module Cli
    class YearDayValidator
      def self.validate_year_and_day(year:, day:, default_untracked_or_done: false)
        year, day = year&.to_s, day&.to_s

        # The first two digits of the year may be omitted.
        year = "20#{year}" if year && year.length == 2

        if day && !year
          raise InputError, "If you specify the day, specify the year also."
        elsif !day
          if default_untracked_or_done
            year, day = Git.new_solutions.last
          end

          unless day
            if year && !Dir.exist?(File.join("src", year))
              Dir.mkdir(File.join("src", year))
              day = "1"
            else
              year, day = Git.last_committed_solution(year:)

              if day && !default_untracked_or_done
                if day == "25"
                  day = :end
                else
                  day = day.next
                end
              end

              if !day || day == :end
                # # TODO refactor to combine this with #progress
                # default_year = "2015"
                # default_day = "1"
                # bootstrap_year_prompt = nil

                # committed_solution_files = `git log --diff-filter=A --name-only --pretty=format: src`
                # if committed_solution_files.empty?
                #   bootstrap_year_prompt = "What year's puzzles do you want to start with? (default: #{default_year})"
                # else
                #   previous_days = (2015..Date.today.year - 1).map(&:to_s).map { [_1, (1..25).map { |day| day.to_s.rjust(2, "0") }] }.to_h
                #   previous_days.merge!(Date.today.year.to_s => (1..Date.today.day).map { |day| day.to_s.rjust(2, "0") }) if Date.today.month == 12

                #   committed_days = committed_solution_files
                #     .split("\n")
                #     .map {
                #       match = _1.match(/(?<year>\d{4})\/(?<day>\d\d).rb$/)
                #       year, day = match[:year], match[:day]
                #       [year, day]
                #     }
                #     .group_by(&:first)
                #     .transform_values { _1.map(&:last) }

                #   default_year, default_day = previous_days
                #     .map { |k, v| [k, v - (committed_days[k] || [])] }
                #     .to_h
                #     .then {
                #       [_1.keys.first, _1.values.first.first]
                #     }
                #   default_day.delete_prefix!("0")

                #   puts "You've recently finished #{year}. Yay!"
                #   bootstrap_year_prompt = "What year do you want to bootstrap next? (default: #{default_year} [at Day #{default_day}])"
                # end

                default_year, default_day = Git.last_committed_solution(exclude_year: year)
                if default_year
                  bootstrap_year_prompt = "What year do you want to bootstrap next? (default: #{default_year} [at Day #{default_day}])"
                else
                  default_year, default_day = "2015", "1"
                  bootstrap_year_prompt = "What year's puzzles do you want to start with? (default: #{default_year})"
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
end
