module DownloadSolutions
  module Api
    class Github
      private attr_reader :user_agent, :auth_token

      # @param auth_token [String]
      def initialize(auth_token:)
        @user_agent = "AdventOfRubyScript/#{Arb::VERSION} by fpsvogel"
        @auth_token = auth_token
      end

      # @param author [String]
      # @param year [Integer]
      # @param day [Integer]
      # @param part [Integer]
      # @return [Array<Hash>, nil] nil if REPOS does not specify the given part.
      def get_solutions(author:, year:, day:, part:)
        part_path = REPOS[author][:"part_#{part}"] || REPOS[author][:either_part]
        return nil unless part_path

        if part_path[:exact_path]
          exact_path = part_path[:exact_path] % {year:, day:, part:}
          response = api_connection.get("/repos/#{author}/#{REPOS[author][:repo]}/contents/#{exact_path}")
          JSON.parse(response.body)
            .then { simplify_response(it, author) }
            .then { [it] }
        else
          response = api_connection.get("/repos/#{author}/#{REPOS[author][:repo]}/contents/#{year}")
          files_regex = part_path[:files].call(year:, day:, part:)
          JSON.parse(response.body)
            .select { |it|
              # If :files regex is specified (rather than :exact_path), then the
              # assumption is that :part_1 and/or :part_2 are specified, rather
              # than :either_part.
              part_1_path = REPOS[author][:part_1]
              if part == 2 && part_1_path
                part_1_files_regex = part_1_path[:files].call(year:, day:, part: 1)
                it["name"].match?(files_regex) && !it["name"].match?(part_1_files_regex)
              else
                it["name"].match?(files_regex)
              end
            }
            .map { simplify_response(it, author) }
        end
      end

      private

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
