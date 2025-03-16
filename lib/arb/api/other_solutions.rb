module Arb
  module Api
    class OtherSolutions
      private attr_reader :year, :day, :part, :gem_directory

      def initialize(year:, day:, part:)
        @year = year
        @day = day
        @part = part
        @gem_directory = Gem.loaded_specs["advent_of_ruby"].gem_dir
      end

      def other_solutions
        unless File.exist?(reddit_file_path)
          return no_solutions_for_year_message
        end

        "#{year} Day #{day.to_i} Part #{part}\n\n" \
          "#{github_solutions}" \
          "#{reddit_solutions if part.to_i == 2}".rstrip + "\n"
      end

      private

      def no_solutions_for_year_message
        "Solutions for #{year} Day #{day.to_i} were not found. Run `gem update " \
          "advent_of_ruby` and try again. If that doesn't work, and it's been " \
          "more than a few days since the end of this year's Advent of Code, " \
          "open an issue at https://github.com/fpsvogel/advent_of_ruby/issues/new" \
          "?labels=bug&title=Add+#{year}+solutions" \
          "&body=Solutions+for+#{year}+need+to+be+added+to+the+gem."
      end

      def github_solutions
        github_directory = File.join(gem_directory, "data", "solutions", "github")

        Dir.children(github_directory)
          .select { |child| File.directory?(File.join(github_directory, child)) }
          .map { |author|
            file_path = File.join(github_directory, author, year.to_s, "#{day.to_s.rjust(2, "0")}_#{part}.yml")
            # The year subdirectory doesn't exist, if the author has no solutions for the year.
            next "" unless File.exist?(file_path)

            solutions = YAML.load_file(file_path)
            next "" if solutions.empty? # if the author has no solutions for the day

            "# #{(solutions.count > 1) ? "Solutions" : "Solution"} by #{author}\n" +
              solutions
                .map { |solution|
                  <<~SOLUTION
                    #{"## #{solution[:name]}\n" if solutions.count > 1}#{solution[:url]}

                    ```ruby
                    #{solution[:solution]}
                    ```

                  SOLUTION
                }
                .join
          }
          .compact
          .join
      end

      def reddit_file_path
        File.join(gem_directory, "data", "solutions", "reddit", "ruby", year.to_s, "#{day.to_s.rjust(2, "0")}.yml")
      end

      def reddit_solutions
        comments = YAML.load_file(reddit_file_path)

        comments.map { |comment|
          reddit_comment_to_markdown(comment)
        }.join
      end

      def reddit_comment_to_markdown(comment, level: 0)
        replies = comment[:replies].map { |reply|
          reddit_comment_to_markdown(reply, level: level + 1)
        }.join("\n\n")

        <<~COMMENT.gsub(/(?:\n\s*){3,}/, "\n\n")
          #{"#" * (level + 1)} #{"↳" * level}#{level.zero? ? "Solution by" : "Reply by"} #{comment[:author]}
          #{comment[:url]}

          #{comment[:body]}

          #{replies unless replies.empty?}
        COMMENT
      end
    end
  end
end
