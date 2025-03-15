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

          (day || 1).upto(day || max_day) do |current_day|
            1.upto(2) do |part|
              path = File.join(year_directory, "#{current_day.to_s.rjust(2, "0")}_#{part}.yml")

              if File.exist?(path) && !force
                puts PASTEL.yellow("Skipping #{author} #{current_year}##{current_day.to_s.rjust(2, "0")}-#{part} as it already exists.")
                next
              end

              solutions = github_api.get_solutions(
                author:,
                year: current_year,
                day: current_day,
                part:
              )

              if solutions.nil?
                next
              elsif solutions.empty?
                puts PASTEL.red("No solution found for #{author} #{current_year}##{current_day.to_s.rjust(2, "0")}-#{part}.")
                next
              end

              File.write(path, solutions.to_yaml(line_width: -1))

              puts "Saved #{PASTEL.blue("#{current_year}##{current_day.to_s.rjust(2, "0")}-#{part}")} to #{path}"
            end
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
