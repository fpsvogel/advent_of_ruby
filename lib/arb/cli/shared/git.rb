module Arb
  module Cli
    class Git
      # Years and days of uncommitted new solutions, or an empty array.
      # @return [Array<Array(String, String)>]
      def self.new_solutions
        output = `git status -su | grep -e "^?? src" -e "^?? spec" -e "^A  src" -e "^A  spec"`
        output.scan(/(?<year>\d{4})\/(?<day>\d\d)(?:_spec)?.rb$/).uniq
      end

      # Years and days of modified existing solutions, or an empty array.
      # @return [Array<Array(String, String)>]
      def self.modified_solutions
        output = `git status -su | grep -e "^ M src" -e "^ M spec" -e "^M  src" -e "^M  spec"`
        output.scan(/(?<year>\d{4})\/(?<day>\d\d)(?:_spec)?.rb$/).uniq
      end

      # Year and day of the latest-date solution in the most recent commit, or nil.
      # @return [Array(String, String), nil]
      def self.last_committed_solution(year: nil, exclude_year: nil)
        if exclude_year
          output = `git log -n 1 --diff-filter=A --name-only --pretty=format: -- src spec ':!src/#{exclude_year}' ':!spec/#{exclude_year}'`
        else
          if year && !Dir.exist?(File.join("src", year))
            return nil
          else
            output = `git log -n 1 --diff-filter=A --name-only --pretty=format: #{File.join("src", year || "")} #{File.join("spec", year || "")}`
          end
        end

        return nil if output.empty?

        output.scan(/(?<year>\d{4})\/(?<day>\d\d)(?:_spec)?.rb$/).last
      end

      # @return [Integer]
      def self.commit_count
        `git rev-list HEAD --count`.to_i
      end

      def self.committed_by_year
        committed_solution_files = `git log --diff-filter=A --name-only --pretty=format: src`

        previous_days = (2015..Date.today.year - 1).map { [_1, (1..25).to_a] }.to_h
        previous_days.merge!(Date.today.year => (1..Date.today.day)) if Date.today.month == 12

        committed_days = committed_solution_files
          .split("\n")
          .reject(&:empty?)
          .map {
            match = _1.match(/(?<year>\d{4})\/(?<day>\d\d).rb$/)
            year, day = match[:year], match[:day]
            [year.to_i, day.to_i]
          }
          .group_by(&:first)
          .transform_values { _1.map(&:last) }

        previous_days.map { |year, days|
          days_hash = days.map { |day|
            [day, committed_days.has_key?(year) && committed_days[year].include?(day)]
          }.to_h

          [year, days_hash]
        }.to_h
      end

      # @return [Boolean]
      def self.repo_exists?
        `git rev-parse --is-inside-work-tree 2> /dev/null`.chomp == "true"
      end

      def self.init!
        `git init`
      end

      def self.commit_all!(message:)
        `git add -A`
        `git commit -m "#{message}"`
      end
    end
  end
end
