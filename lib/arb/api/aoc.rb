module Arb
  module Api
    class Aoc
      private attr_reader :connection

      def initialize(cookie:)
        @connection = Faraday.new(
          url: "https://adventofcode.com",
          headers: {
            "Cookie" => "session=#{cookie}",
            "User-Agent" => "github.com/fpsvogel/advent_of_ruby by fps.vogel@gmail.com"
          }
        )
      end

      def input(year:, day:)
        logged_in {
          connection.get("/#{year}/day/#{day.delete_prefix("0")}/input")
        }
      end

      def instructions(year:, day:)
        logged_in {
          connection.get("/#{year}/day/#{day.delete_prefix("0")}")
        }
      end

      def submit(year:, day:, part:, answer:)
        logged_in {
          connection.post(
            "/#{year}/day/#{day.delete_prefix("0")}/answer",
            "level=#{part}&answer=#{answer}"
          )
        }
      end

      private

      LOGGED_OUT_RESPONSE = "Please log in"

      def logged_in(&block)
        while (response = block.call.body).include? LOGGED_OUT_RESPONSE
          Cli::WorkingDirectory.refresh_aoc_cookie!
          initialize(cookie: ENV["AOC_COOKIE"])
        end

        response
      end
    end
  end
end
