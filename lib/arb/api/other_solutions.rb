module Arb
  module Api
    class OtherSolutions
      include HTTParty
      base_uri "https://raw.githubusercontent.com"

      UI_URI = "https://github.com"

      private attr_reader :headers

      PATHS = {
        "eregon" => ->(year, day, part) {
          if part == "1"
            [
              "adventofcode/tree/master/#{year}/#{day}.rb",
              "adventofcode/tree/master/#{year}/#{day}a.rb",
            ]
          elsif part == "2"
            ["adventofcode/tree/master/#{year}/#{day}b.rb"]
          end
        },
        "gchan" => ->(year, day, part) {
          ["advent-of-code-ruby/tree/main/#{year}/day-#{day.rjust(2, "0")}/day-#{day.rjust(2, "0")}-part-#{part}.rb"]
        },
        "ahorner" => ->(year, day, part) {
          return [] if part == "1"
          ["advent-of-code/tree/main/lib/#{year}/#{day.rjust(2, "0")}.rb"]
        },
        "ZogStriP" => ->(year, day, part) {
          return [] if part == "1"

          puzzle_name = File.read(Files::Instructions.path(year, day))
            .match(/## --- Day \d\d?: (.+)(?= ---)/)
            .captures
            .first
            .downcase
            .gsub(" ", "_")

          ["adventofcode/tree/master/#{year}/#{day.rjust(2, "0")}_#{puzzle_name}.rb"]
        },
        "erikw" => ->(year, day, part) {
          ["advent-of-code-solutions/tree/main/#{year}/#{day.rjust(2, "0")}/part#{part}.rb"]
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
        @headers = {
          "User-Agent" => "github.com/fpsvogel/ruby-advent-of-code by fps.vogel@gmail.com"
        }
      end

      def other_solutions(year, day, part)
        "# #{year} Day #{day} Part #{part}\n\n" +
          PATHS
          .map { |username, path_builder|
            actual_path = nil
            solution = nil
            paths = path_builder.call(year, day, part)

            paths.each do |path|
              next if solution
              response = self.class.get("/#{username}/#{path.sub("/tree/", "/")}", headers:)
              next if response.not_found?

              actual_path = path
              solution = (EDITS[username] || :itself.to_proc).call(response)
            end

            if solution
              <<~TPL
                # ------------------------------------------------------------------------------
                # #{username}: #{UI_URI}/#{username}/#{actual_path}
                # ------------------------------------------------------------------------------

                #{solution}

              TPL
            end
          }
          .compact
          .join
          .strip + "\n"
      end
    end
  end
end
