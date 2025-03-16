module DownloadSolutions
  module Cli
    def self.reddit(year: nil, day: nil, languages: ["ruby"], force: false)
      validate_year_and_day(year:, day:)

      language_names = PASTEL.blue(languages.join(", "))
      detail = "for #{language_names}"
      output_initial_message(source: "Reddit", year:, day:, force:, detail:)

      language_directory = File.join("data", "solutions", "reddit", languages.join("-"))
      Dir.mkdir(language_directory) unless Dir.exist?(language_directory)

      max_year, max_day = max_year_and_day(year:, day:)

      (year || 2015).upto(year || max_year) do |current_year|
        year_directory = File.join("data", "solutions", "reddit", languages.join("-"), current_year.to_s)
        Dir.mkdir(year_directory) unless Dir.exist?(year_directory)

        (day || 1).upto(day || max_day) do |current_day|
          path = File.join("data", "solutions", "reddit", languages.join("-"), year.to_s, "#{current_day.to_s.rjust(2, "0")}.yml")

          if File.exist?(path) && !force
            puts PASTEL.yellow("Skipping #{PASTEL.yellow.bold("#{current_year}##{current_day.to_s.rjust(2, "0")}")} as it already exists.")
            puts
            next
          end

          comments = reddit_api.get_comments(
            year: current_year,
            day: current_day,
            languages:
          )

          File.write(path, comments.to_yaml(line_width: -1))

          puts "Saved #{PASTEL.blue("#{current_year}##{current_day.to_s.rjust(2, "0")}")} to #{path}"
          puts
        end
      end
    rescue InputError => e
      puts PASTEL.red(e.message)
    end

    private_class_method def self.reddit_api
      return @reddit_api if @reddit_api

      reddit_api_keys = %w[
        REDDIT_CLIENT_ID
        REDDIT_CLIENT_SECRET
        REDDIT_USERNAME
        REDDIT_PASSWORD
      ]

      Dotenv.load
      Dotenv.require_keys(reddit_api_keys)

      reddit_api_kwargs = %i[client_id client_secret username password]
        .zip(reddit_api_keys.map { ENV[it] })
        .to_h

      @reddit_api = Api::Reddit.new(**reddit_api_kwargs)
    end
  end
end
