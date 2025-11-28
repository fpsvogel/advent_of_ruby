module DownloadSolutions
  module Api
    class Github
      REPOS = {
        "ahorner" => {
          repo: "advent-of-code",
          year_directory: "lib/%<year>d",
          both_parts: "%<day>.2d.rb"
        },
        "eregon" => {
          repo: "adventofcode",
          part_1: ->(day:) {
            /\A#{day}(?:a.*)?\.rb\z/
          },
          part_2: ->(day:) {
            /\A#{day}(?:b.*|\D*)\.rb\z/
          }
        },
        "erikw" => {
          repo: "advent-of-code-solutions",
          day_directory: "%<day>.2d",
          part_1: "part1.rb",
          part_2: "part2.rb",
          edits: ->(file_contents) {
            # Remove the first 3 lines (boilerplate).
            file_contents.lines[3..].join
          }
        },
        "gchan" => {
          repo: "advent-of-code-ruby",
          day_directory: "day-%<day>.2d",
          part_1: "day-%<day>.2d-part-1.rb",
          part_2: "day-%<day>.2d-part-2.rb",
          # rarely, e.g. https://github.com/gchan/advent-of-code-ruby/tree/main/2023/day-17
          both_parts: "day-%<day>.2d-part-1-and-2.rb",
          edits: ->(file_contents) {
            # Remove the first 5 lines (boilerplate).
            file_contents.lines[5..].join
          }
        },
        "ZogStriP" => {
          repo: "adventofcode",
          both_parts: "%<day>.2d.rb"
        }
      }
    end
  end
end
