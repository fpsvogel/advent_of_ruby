module DownloadSolutions
  module Api
    class Github
      UnexpectedResponseError = Class.new(StandardError)
      NotFoundResponseError = Class.new(StandardError)

      private attr_reader :user_agent, :auth_token

      # @param auth_token [String]
      def initialize(auth_token:)
        @user_agent = "AdventOfRubyScript/#{Arb::VERSION} by fpsvogel"
        @auth_token = auth_token
      end

      # @param author [String]
      # @param year [Integer]
      # @param day [Integer]
      # @param max_day [Integer]
      # @param force [Boolean]
      # @param existing_solutions [Array<Array(Integer, Integer)>]
      # @return [Array<Hash>, nil] nil if the year directory doesn't exist for the author.
      def get_solutions(author:, year:, input_day: nil, max_day: 25, force: false, existing_solutions: [])
        # return nil if day == 25 && part == 2
        solutions = {new: {}, skipped: [], not_found: []}

        year_directory = (REPOS[author][:year_directory] || "%<year>d") % {year:}
        year_response = api_connection.get("/repos/#{author}/#{REPOS[author][:repo]}/contents/#{year_directory}")
        if year_response.status == 404
          solutions[:not_found] = (1..max_day).flat_map { |day|
            [[day, 1], ([day, 2] unless day == 25)]
          }.compact
          return solutions
        end
        year_files = JSON.parse(year_response.body)

        (input_day || 1).upto(input_day || max_day) do |day|
          if REPOS[author][:day_directory]
            if !force && existing_solutions.any? { |existing_day, _existing_part| existing_day == day }
              solutions[:skipped] << [day, 1]
              solutions[:skipped] << [day, 1] unless day == 25
              next
            end
            day_directory = REPOS[author][:day_directory] % {day:}
            day_response = api_connection.get("/repos/#{author}/#{REPOS[author][:repo]}/contents/#{year_directory}/#{day_directory}")
            if day_response.status == 404
              solutions[:not_found] << [day, 1]
              solutions[:not_found] << [day, 2] unless day == 25
              next
            end
            day_files = JSON.parse(day_response.body)
          end

          1.upto(2) do |part|
            next if day == 25 && part == 2

            if !force && existing_solutions.include?([day, part])
              solutions[:skipped] << [day, part]
            else
              solution = get_solution(author:, year:, day:, part:, year_files:, day_files:)

              if solution.empty?
                solutions[:not_found] << [day, part]
              else
                solutions[:new][[day, part]] = solution
              end
            end
          end
        end

        solutions
      end

      private

      def get_solution(author:, year:, day:, part:, year_files:, day_files: nil)
        exact_path = (REPOS[author][:"part_#{part}"] || REPOS[author][:both_parts]).is_a?(String)

        if exact_path
          (day_files || year_files)
            .select {
              if REPOS[author][:both_parts] && it["name"] == REPOS[author][:both_parts] % {year:, day:}
                next if part == 1 && day != 25 # both_parts will be saved in part 2
                true
              elsif REPOS[author][:"part_#{part}"]
                it["name"] == REPOS[author][:"part_#{part}"] % {year:, day:}
              end
            }
            .map { simplify_response(it, author) }
        else # regex-matched paths
          (day_files || year_files)
            .select {
              if REPOS[author][:both_parts] && it["name"].match?(REPOS[author][:both_parts].call(day:))
                next if part == 1 && day != 25 # both_parts will be saved in part 2
                true
              elsif REPOS[author][:part_1] && REPOS[author][:part_2]
                if part == 2
                  it["name"].match?(REPOS[author][:part_2].call(day:)) &&
                    !it["name"].match?(REPOS[author][:part_1].call(day:))
                else
                  it["name"].match?(REPOS[author][:part_1].call(day:))
                end
              end
            }
            .map { simplify_response(it, author) }
        end
      end

      def simplify_response(response, author)
        solution = raw_connection.get(response["download_url"]).body
        solution = REPOS[author][:edits].call(solution) if REPOS[author][:edits]
        {
          name: response["name"],
          url: response["html_url"].rpartition("/").first,
          solution: solution.strip
        }
      end

      def api_connection
        @api_connection ||= Faraday.new(
          url: "https://api.github.com",
          headers: {
            "User-Agent" => user_agent,
            "Accept" => "application/vnd.github+json"
          }
        ) do |f|
          f.request :authorization, "token", -> { auth_token }
          f.request :retry, {
            max: 5,
            interval: 0.5,
            interval_randomness: 0.5,
            backoff_factor: 2
          }
        end
      end

      def raw_connection
        @raw_connection ||= Faraday.new(
          url: "https://raw.githubusercontent.com",
          headers: {"User-Agent" => user_agent}
        ) do |f|
          f.request :retry, {
            max: 5,
            interval: 0.5,
            interval_randomness: 0.5,
            backoff_factor: 2
          }
        end
      end
    end
  end
end
