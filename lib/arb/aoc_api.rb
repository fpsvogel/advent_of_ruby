module Arb
  class AocApi
    include HTTParty
    base_uri "https://adventofcode.com"

    private attr_reader :headers

    def initialize(cookie)
      @headers = {
        "Cookie" => "session=#{cookie}",
        "User-Agent" => "github.com/fpsvogel/ruby-advent-of-code by fps.vogel@gmail.com",
      }
    end

    def input(year, day)
      logged_in {
        self.class.get("/#{year}/day/#{day}/input", headers:)
      }
    end

    def instructions(year, day)
      logged_in {
        self.class.get("/#{year}/day/#{day}", headers:)
      }
    end

    def submit(year, day, part, answer)
      logged_in {
        self.class.post(
          "/#{year}/day/#{day}/answer",
          body: { level: part, answer: },
          headers:,
        )
      }
    end

    private

    LOGED_OUT_RESPONSE = "Puzzle inputs differ by user.  Please log in to get your puzzle input.\n"

    def logged_in(&block)
      while (response = block.call.to_s) == LOGED_OUT_RESPONSE
        Config.refresh_aoc_cookie!
        initialize(ENV["AOC_COOKIE"])
      end

      response
    end
  end
end
