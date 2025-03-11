module DownloadSolutions
  module Api
    class Reddit
      class Params
        attr_reader :year, :day, :languages, :connection, :megathread_path, :thread_id
        attr_accessor :initial_response, :original_comments, :more_childrens, :comments

        # @param year [Integer]
        # @param day [Integer]
        # @param languages [Array<String>] e.g. ["ruby"]
        def initialize(year:, day:, languages:, connection:)
          @year = year
          @day = day
          @languages = languages
          @connection = connection
          @megathread_path = build_megathread_path(year:, day:)
          @thread_id = "t3_#{megathread_id(year:, day:)}"
        end

        private

        def build_megathread_path(year:, day:)
          if year == 2015 && day == 1
            return "/r/programming/comments/#{Reddit::MEGATHREAD_IDS[2015][0]}/daily_programming_puzzles_at_advent_of_code.json"
          end

          slug = "day_#{day.to_i}_solutions"
          slug = "#{year.to_i}_#{slug}" if year > 2015

          "/r/adventofcode/comments/#{megathread_id(year:, day:)}/#{slug}.json"
        end

        def megathread_id(year:, day:)
          Reddit::MEGATHREAD_IDS[year.to_i][day - 1]
        end
      end
    end
  end
end
