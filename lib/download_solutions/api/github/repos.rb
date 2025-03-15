module DownloadSolutions
  module Api
    class Github
      REPOS = {
        "ahorner" => {
          repo: "advent-of-code",
          part_2: {
            exact_path: "lib/%<year>d/%<day>.2d.rb"
          }
        },
        "eregon" => {
          repo: "adventofcode",
          part_1: {
            files: ->(year:, day:, part:) {
              /\A#{day}(?:a.*)?\.rb\z/
            }
          },
          part_2: {
            files: ->(year:, day:, part:) {
              /\A#{day}(?:b.*|\D*)\.rb\z/
            }
          }

        },
        "erikw" => {
          repo: "advent-of-code-solutions",
          either_part: {
            exact_path: "%<year>d/%<day>.2d/part%<part>d.rb"
          },
          edits: ->(file_contents) {
            # Remove the first 3 lines (boilerplate).
            file_contents.lines[3..].join
          }
        },
        "gchan" => {
          repo: "advent-of-code-ruby",
          either_part: {
            exact_path: "%<year>d/day-%<day>.2d/day-%<day>.2d-part-%<part>d.rb"
          },
          part_2: {
            exact_path: "%<year>d/day-%<day>.2d/day-%<day>.2d-part-1-and-2.rb"
          },
          edits: ->(file_contents) {
            # Remove the first 5 lines (boilerplate).
            file_contents.lines[5..].join
          }
        },
        "ZogStriP" => {
          repo: "adventofcode-old",
          part_2: {
            files: ->(year:, day:, part:) {
              /\A#{day.to_s.rjust(2, "0")}_.+\.rb\z/
            }
          },
          edits: ->(file_contents) {
            # Remove input at the end of the file.
            file_contents.split("\n__END__").first
          }
        }
      }

      # def other_solutions(year:, day:, part:)
      #   "# #{year} Day #{day} Part #{part}\n\n" +
      #     PATHS
      #       .map { |username, path_builder|
      #       actual_path = nil
      #       solution = nil
      #       paths = path_builder.call(year:, day:, part:)

      #       paths.each do |path|
      #         next if solution
      #         response = connection.get("/#{username}/#{path.sub("/tree/", "/")}")
      #         next if response.status == 404

      #         actual_path = path
      #         solution = (EDITS[username] || :itself.to_proc).call(response.body)
      #       end

      #       if solution
      #         <<~SOLUTION
      #           # ------------------------------------------------------------------------------
      #           # #{username}: #{UI_URI}/#{username}/#{actual_path}
      #           # ------------------------------------------------------------------------------

      #           #{solution}

      #         SOLUTION
      #       end
      #     }
      #       .compact
      #       .join
      #       .strip + "\n"
      # end
    end
  end
end
