# TODO
# Add https://github.com/ZogStriP/adventofcode-old
# Convert into a separate app that downloads all of a year's solutions for any language.
#   - each of the transformations in PATHS will become an executable script
#     so that the user can add scripts for repos containing solutions for their
#     own chosen languge.
# Use GitHub API to get all filenames then select on day/part.
#   - e.g. to get all variants https://github.com/eregon/adventofcode/tree/master/2024
#   - and e.g. to avoid having to match the exact name for ZogStriP/adventofcode-old
# Get solutions from Reddit too https://www.reddit.com/dev/api/oauth#GET_comments_{article}
#   - similar project: https://github.com/rpalo/aoc_language_bot
module Arb
  module Api
    class OtherSolutions
      UI_URI = "https://github.com"

      private attr_reader :connection

      PATHS = {
        "eregon" => ->(year:, day:, part:) {
          if part == "1"
            [
              "adventofcode/tree/master/#{year}/#{day.delete_prefix("0")}.rb",
              "adventofcode/tree/master/#{year}/#{day.delete_prefix("0")}a.rb",
            ]
          elsif part == "2"
            ["adventofcode/tree/master/#{year}/#{day.delete_prefix("0")}b.rb"]
          end
        },
        "gchan" => ->(year:, day:, part:) {
          ["advent-of-code-ruby/tree/main/#{year}/day-#{day}/day-#{day}-part-#{part}.rb"]
        },
        "ahorner" => ->(year:, day:, part:) {
          return [] if part == "1"
          ["advent-of-code/tree/main/lib/#{year}/#{day}.rb"]
        },
        "ZogStriP" => ->(year:, day:, part:) {
          return [] if part == "1"

          puzzle_name = File.read(Files::Instructions.path(year:, day:))
            .match(/## --- Day \d\d?: (.+)(?= ---)/)
            .captures
            .first
            .downcase
            .gsub(" ", "_")

          ["adventofcode/tree/master/#{year}/#{day}_#{puzzle_name}.rb"]
        },
        "erikw" => ->(year:, day:, part:) {
          ["advent-of-code-solutions/tree/main/#{year}/#{day}/part#{part}.rb"]
        },
      }

      EDITS = {
        "gchan" => ->(file_str) {
          # Remove the first 5 lines (boilerplate).
          file_str.lines[5..].join
        },
        "ZogStriP" => ->(file_str) {
          # Remove input at the end of the file.
          file_str.split("\n__END__").first
        },
        "erikw" => ->(file_str) {
          # Remove the first 3 lines (boilerplate).
          file_str.lines[3..].join
        },
      }

      def initialize
        @connection = Faraday.new(
          url: "https://raw.githubusercontent.com",
          headers: {
            "User-Agent" => "github.com/fpsvogel/advent_of_ruby by fps.vogel@gmail.com",
          }
        )
      end

      def other_solutions(year:, day:, part:)
        "# #{year} Day #{day} Part #{part}\n\n" +
          PATHS
          .map { |username, path_builder|
            actual_path = nil
            solution = nil
            paths = path_builder.call(year:, day:, part:)

            paths.each do |path|
              next if solution
              response = connection.get("/#{username}/#{path.sub("/tree/", "/")}")
              next if response.status == 404

              actual_path = path
              solution = (EDITS[username] || :itself.to_proc).call(response.body)
            end

            if solution
              <<~SOLUTION
                # ------------------------------------------------------------------------------
                # #{username}: #{UI_URI}/#{username}/#{actual_path}
                # ------------------------------------------------------------------------------

                #{solution}

              SOLUTION
            end
          }
          .compact
          .join
          .strip + "\n"
      end
    end
  end
end
