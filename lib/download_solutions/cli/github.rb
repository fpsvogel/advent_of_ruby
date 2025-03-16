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

          existing_solutions =
            if Dir.exist?(year_directory)
              Dir.entries(year_directory)
                .filter_map {
                  it.delete_suffix(".yml").split("_").map(&:to_i) if it.end_with?(".yml")
                }.sort
            else
              []
            end

          solutions = github_api.get_solutions(
            author:,
            year: current_year,
            input_day: day,
            max_day:,
            force:,
            existing_solutions:
          )

          skipped_list = solutions_str(solutions[:skipped])
          if solutions[:skipped].any?
            puts "#{PASTEL.yellow.bold("Skipping")} from #{author} #{current_year}, already existing: #{PASTEL.yellow(skipped_list)}"
          end

          not_found_list = solutions_str(solutions[:not_found])
          if solutions[:not_found].any?
            puts "#{PASTEL.red.bold("Not found")} from #{author} #{current_year}: #{PASTEL.red(not_found_list)}"
            if solutions[:not_found].size < 49
              # Save empty files for not found solutions, so that they won't be
              # attempted to be downloaded again.
              Dir.mkdir(year_directory) unless Dir.exist?(year_directory)
              solutions[:not_found].each do |(day, part)|
                path = File.join(year_directory, "#{day.to_s.rjust(2, "0")}_#{part}.yml")
                File.write(path, [].to_yaml)
              end
            end
          end

          if solutions[:new].any?
            Dir.mkdir(year_directory) unless Dir.exist?(year_directory)
            solutions[:new].each do |(day, part), content|
              path = File.join(year_directory, "#{day.to_s.rjust(2, "0")}_#{part}.yml")
              File.write(path, content.to_yaml(line_width: -1))
            end

            new_list = solutions_str(solutions[:new].keys)
            puts "#{PASTEL.blue.bold("Saved")} from #{author} #{current_year}: #{PASTEL.blue(new_list)}"
            puts "Saved to #{year_directory}"
          end
        end

        puts
      end
    rescue InputError => e
      puts PASTEL.red(e.message)
    end

    private_class_method def self.solutions_str(solutions)
      if solutions.count == 49
        "all"
      else
        solutions.sort.map { it.join(".") }.join(", ")
      end
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
