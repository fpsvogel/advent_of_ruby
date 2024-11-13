module Arb
  module Files
    class Input
      def self.path(year:, day:)
        year_directory = File.join("input", year)
        File.join(year_directory, "#{day}.txt")
      end

      def self.download(year:, day:, notify_exists: true)
        Dir.mkdir("input") unless Dir.exist?("input")
        year_directory = File.join("input", year)
        Dir.mkdir(year_directory) unless Dir.exist?(year_directory)
        file_path = File.join(year_directory, "#{day}.txt")

        if File.exist?(file_path)
          puts "Already exists: #{file_path}" if notify_exists
        else
          aoc_api = Api::Aoc.new(cookie: ENV["AOC_COOKIE"])
          response = aoc_api.input(year:, day:)

          File.write(file_path, response)
        end

        file_path
      end
    end
  end
end
