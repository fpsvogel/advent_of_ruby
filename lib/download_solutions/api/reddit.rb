module DownloadSolutions
  module Api
    class Reddit
      MaxSleepCountReachedError = Class.new(StandardError)
      MultipleMoreChildrensError = Class.new(StandardError)

      private attr_reader :user_agent, :client_id, :client_secret, :username, :password

      # @param client_id [String]
      # @param client_secret [String]
      # @param username [String]
      # @param password [String]
      def initialize(client_id:, client_secret:, username:, password:)
        @user_agent = "AdventOfRubyScript/#{Arb::VERSION} by fpsvogel"
        @client_id = client_id
        @client_secret = client_secret
        @username = username
        @password = password
      end

      # @param year [Integer]
      # @param day [Integer]
      # @param languages [Array<String>] e.g. ["ruby"]
      # @return [Array<Hash>]
      #
      # @raise [MaxSleepCountReachedError] if Reddit seemingly throttled for an
      #   unusually long time, "seemingly" because the only sign is an empty
      #   JSON response body after loading additional comments.
      # @raise [MultipleMoreChildrensError] if there are multiple "more children"
      #   nodes for the thread or a comment; only one at a time is expected.
      def get_comments(year:, day:, languages:)
        params = Params.new(
          year:,
          day:,
          languages:,
          connection:
        )

        initial_response = GetInitialResponse.call(params:)
        params.initial_response = initial_response

        # Keep unfetched replies ("more children" nodes) separate so that after
        # filtering, the replies to filtered-in comments can then be fetched.
        original_comments, more_childrens = GetSerialComments.call(params:)
        params.original_comments = original_comments
        params.more_childrens = more_childrens

        filtered_comments = FilterByLanguage.call(params:)
        params.comments = filtered_comments

        # These operations modify params#comments in place.
        AddMissingReplies.call(params:)
        RejectUnwantedReplies.call(params:)
        CleanBodies.call(params:)
        RemoveLanguageTags.call(params:)
        RemoveIds.call(params:)

        params.comments
      end

      private

      def connection
        @connection ||= Faraday.new(
          url: "https://oauth.reddit.com",
          headers: {
            "User-Agent" => user_agent,
            "Accept" => "application/json"
          }
        ) do |f|
          f.request :authorization, "Bearer", -> { auth_token }
          f.request :retry, {
            max: 5,
            interval: 0.5,
            interval_randomness: 0.5,
            backoff_factor: 2
          }
        end
      end

      def auth_token
        connection = Faraday.new(
          url: "https://www.reddit.com",
          headers: {
            "User-Agent" => user_agent
          }
        ) do |f|
          f.request :authorization, :basic, client_id, client_secret
          f.response :json
        end

        response = connection.post(
          "/api/v1/access_token",
          "grant_type=password&username=#{username}&password=#{password}"
        )

        response.body["access_token"]
      end
    end
  end
end
