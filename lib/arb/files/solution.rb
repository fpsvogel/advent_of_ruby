module Arb
  module Files
    class Solution
      def self.create(year, day)
        year_directory = File.join("src", year)
        Dir.mkdir(year_directory) unless Dir.exist?(year_directory)

        file_path = File.join(year_directory, "#{day}.rb")

        if File.exist?(file_path)
          puts "Already exists: #{file_path}"
        else
          File.write(file_path, template(year, day))
        end

        file_path
      end

      def self.template(year, day)
        <<~SRC
          # https://adventofcode.com/#{year}/day/#{day.delete_prefix("0")}
          module Year#{year}
            class Day#{day}
              def part_1(input_file)
                lines = input_file.readlines(chomp: true)

                nil
              end

              def part_2(input_file)
                lines = input_file.readlines(chomp: true)

                nil
              end
            end
          end
        SRC
      end
    end
  end
end
