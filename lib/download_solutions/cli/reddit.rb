module DownloadSolutions
  module Cli
    def self.reddit(year: nil, day: nil, languages: ["ruby"], force: false)
      if day && year.nil?
        raise InputError, "Year must be specified when day is specified."
      end
      if !year.between?(2015, Date.today.year)
        raise InputError, "Year must be between 2015 and this year."
      end
      if day && !day.between?(1, 25) && Date.new(year, 12, day) > Date.today
        raise InputError, "Day must be between 1 and 25, and <= today."
      end

      force_description = PASTEL.red("FORCE ") if force
      year_description = year.nil? ? "all years" : "#{year}"
      day_description = day.nil? ? "" : "##{day.to_s.rjust(2, "0")}"
      time_description = PASTEL.blue("#{year_description}#{day_description}")
      language_names = PASTEL.blue(languages.join(", "))

      puts "#{force_description}Downloading Reddit solutions from #{time_description} for #{language_names}..."
      puts

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

      reddit_api = Api::Reddit.new(**reddit_api_kwargs)

      max_year, max_day = if Date.today.year == year && Date.today.month == 12
        [Date.today.year, Date.today.day]
      else
        [Date.today.year - 1, 25]
      end

      language_directory = File.join("data", "solutions", "reddit", languages.join("-"))
      Dir.mkdir(language_directory) unless Dir.exist?(language_directory)

      (year || 2015).upto(year || max_year) do |current_year|
        year_directory = File.join("data", "solutions", "reddit", languages.join("-"), current_year.to_s)
        Dir.mkdir(year_directory) unless Dir.exist?(year_directory)

        (day || 1).upto(day || max_day) do |current_day|
          path = File.join("data", "solutions", "reddit", languages.join("-"), year.to_s, "#{current_day.to_s.rjust(2, "0")}.yml")

          if File.exist?(path) && !force
            puts PASTEL.yellow("Skipping #{current_year}##{current_day.to_s.rjust(2, "0")} as it already exists.")
            puts
            next
          end

          comments = reddit_api.get_comments(
            year: current_year,
            day: current_day,
            languages:,
          )

          File.write(path, comments.to_yaml(line_width: -1))

          puts "Saved #{PASTEL.blue("#{current_year}##{current_day.to_s.rjust(2, "0")}")} to #{path}"
          puts
        end
      end

      # TODO separately in Arb module, transform to Markdown:
      #
      # comments = YAML.load_file(...)
      #
      # comments_markdown = comments.map { |comment|
      #   comment_to_markdown(comment)
      # }.join
      #
      # File.write(
      #   ...,
      #   comments_markdown,
      # )
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
  end
end
