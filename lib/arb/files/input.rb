module Arb
  module Files
    class Input
      def self.download(year, day, notify_exists: true)
        year_directory = File.join("input", year)
        Dir.mkdir(year_directory) if !Dir.exist?(year_directory)

        padded_day = day.rjust(2, "0")
        file_path = File.join(year_directory, "#{padded_day}.txt")

        if File.exist?(file_path)
          puts "Already exists: #{file_path}" if notify_exists
        else
          aoc_api = Api::Aoc.new(ENV["AOC_COOKIE"])
          response = aoc_api.input(year, day)

          File.write(file_path, response)
        end

        file_path
      end
    end
  end
end
