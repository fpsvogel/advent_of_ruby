module Arb
  module Files
    class Instructions
      def self.path(year, day)
        year_directory = File.join("instructions", year)
        Dir.mkdir("instructions") unless Dir.exist?("instructions")
        Dir.mkdir(year_directory) unless Dir.exist?(year_directory)

        padded_day = day.rjust(2, "0")

        File.join(year_directory, "#{padded_day}.md")
      end

      def self.download(year, day, notify_exists: true, overwrite: false)
        file_path = path(year, day)

        if File.exist?(file_path) && !overwrite
          puts "Already exists: #{file_path}" if notify_exists
        else
          url = "https://adventofcode.com/#{year}/day/#{day}"

          aoc_api = Api::Aoc.new(ENV["AOC_COOKIE"])
          response = aoc_api.instructions(year, day)
          instructions = response.match(/(?<=<main>).+(?=<\/main>)/m).to_s
          markdown_instructions = ReverseMarkdown.convert(instructions).strip
          markdown_instructions = markdown_instructions
            .sub(/\nTo play, please identify yourself via one of these services:.+/m, "")
            .sub(/\nTo begin, \[get your puzzle input\].+/m, "")
            .sub(/\n\<form method="post".+/m, "")
            .sub(/\nAt this point, you should \[return to your Advent calendar\].+/m, "")
            .concat("\n#{url}\n")

          File.write(file_path, markdown_instructions)
        end

        file_path
      end
    end
  end
end
