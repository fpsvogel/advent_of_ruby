module DownloadSolutions
  module Cli
    def self.github(year: nil, day: nil, author: nil, force: false)
      validate_year_and_day(year:, day:)

      author_name = author.nil? ? "all authors" : PASTEL.blue(author)
      detail = "by #{author_name}"
      output_initial_message(source: "GitHub", year:, day:, force:, detail:)

      github_directory = File.join("data", "solutions", "github")

      repos = Api::Github::REPOS
      if author
        if repos.key?(author)
          repos = repos.select { _1 == author }
        else
          raise InputError, "Repo author #{PASTEL.blue(author)} not found."
        end
      end

      max_year, max_day = max_year_and_day(year:, day:)

      authors = repos.keys
      authors.each do |author|
        author_directory = File.join(github_directory, author)
        Dir.mkdir(author_directory) unless Dir.exist?(author_directory)

        (year || 2015).upto(year || max_year) do |current_year|
          year_directory = File.join(author_directory, current_year.to_s)
          Dir.mkdir(year_directory) unless Dir.exist?(year_directory)

          existing_solutions = Dir.entries(year_directory)
            .filter_map {
              it.delete_suffix(".yml").split("_").map(&:to_i) if it.end_with?(".yml")
            }.sort

          solutions = github_api.get_solutions(
            author:,
            year: current_year,
            input_day: day,
            max_day:,
            force:,
            existing_solutions:
          )

          skipped_list = solutions[:skipped].sort.map { it.join(".") }.join(", ")
          if solutions[:skipped].any?
            puts "#{PASTEL.yellow("Skipping")} from #{author} #{current_year}, already existing: #{PASTEL.yellow(skipped_list)}"
          end

          not_found_list = solutions[:not_found].sort.map { it.join(".") }.join(", ")
          if solutions[:not_found].any?
            puts "#{PASTEL.red("Not found")} from #{author} #{current_year}: #{PASTEL.red(not_found_list)}"
          end

          if solutions[:new].any?
            solutions[:new].each do |(day, part), content|
              path = File.join(year_directory, "#{day.to_s.rjust(2, "0")}_#{part}.yml")
              File.write(path, content.to_yaml(line_width: -1))
            end

            new_list = solutions[:new].keys.sort.map { it.join(".") }.join(", ")
            puts "#{PASTEL.blue("Saved")} from #{author} #{current_year}: #{PASTEL.blue(new_list)}"
            puts PASTEL.blue("Saved to #{year_directory}")
          end
        end

        puts
      end
    rescue InputError => e
      puts PASTEL.red(e.message)
    end

    def comment_to_markdown(comment, level: 0)
      replies = comment[:replies].map { |reply|
        comment_to_str(reply, level: level + 1)
      }.join("\n\n")

      <<~COMMENT.gsub(/(?:\n\s*){3,}/, "\n\n")
        #{"#" * (level + 1)} #{"↳" * level}#{level.zero? ? "Solution by" : "Reply by"} #{comment[:author]}
        #{comment[:url]}

        #{comment[:body]}

        #{replies unless replies.empty?}
      COMMENT
    end

    private_class_method def self.github_api
      return @github_api if @github_api

      github_token = "GITHUB_TOKEN"

      Dotenv.load
      Dotenv.require_keys([github_token])

      @github_api = Api::Github.new(auth_token: ENV[github_token])
    end
  end
end
