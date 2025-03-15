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
      # @param part [Integer]
      # @return [Array<Hash>, nil] nil if REPOS does not specify the given part.
      def get_solutions(author:, year:, day:, part:)
        return nil if day == 25 && part == 2

        part_path = (REPOS[author][:either_part] unless part == 1 && day != 25 && REPOS[author][:part_2]) ||
          REPOS[author][:"part_#{part}"] ||
          (REPOS[author][:part_2] if day == 25 && part == 1)
        return nil unless part_path

        if part_path[:exact_path]
          exact_path = part_path[:exact_path] % {year:, day:, part:}
          # Fall back to :part_2 exact path if :either_part exact path not found.
          # This is for cases where there is a single file for both parts
          # by an author who ordinarily has separate files for each part,
          # e.g. https://github.com/gchan/advent-of-code-ruby/tree/main/2023/day-17
          fallback_exact_path = REPOS.dig(author, :part_2, :exact_path) % {year:, day:} if REPOS.dig(author, :part_2, :exact_path)
          response = get_response(author:, path: exact_path, fallback_path: fallback_exact_path)

          JSON.parse(response.body)
            .then { simplify_response(it, author) }
            .then { [it] }
        else # :files (regex)
          response = get_response(author:, path: year)

          files_regex = part_path[:files].call(year:, day:, part:)
          JSON.parse(response.body)
            .select {
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
      rescue NotFoundResponseError
        []
      end

      private

      def get_response(author:, path:, fallback_path: nil)
        response = api_connection.get("/repos/#{author}/#{REPOS[author][:repo]}/contents/#{path}")

        if response.status == 404
          if fallback_path
            response = get_response(author:, path: fallback_path)
          else
            raise NotFoundResponseError
          end
        elsif response.status != 200
          raise UnexpectedResponseError, "Unexpected HTTP status: #{it["status"]}. Response: #{response}"
        end

        response
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
