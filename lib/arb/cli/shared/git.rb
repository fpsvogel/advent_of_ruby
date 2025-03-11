module Arb
  module Cli
    class Git
      # A hash whose keys are ["<year>", "<day>"] of new solutions or specs, and
      # and whose values are the names of the modified files (solution, spec, or both).
      # @return [Array<Array(String, String)>]
      def self.uncommitted_puzzles
        output = `git status -su | grep -e "^?? src" -e "^?? spec" -e "^A  src" -e "^A  spec"`
        filenames = output.scan(/(?:src|spec)\/\d{4}\/\d\d(?:_spec)?.rb/).uniq
        filenames.group_by { |filename|
          filename
            .match(/(?<year>\d{4})\/(?<day>\d\d)(?:_spec)?.rb$/)
            .captures
        }
      end

      # A hash whose keys are ["<year>", "<day>"] of modified existing solutions
      # or specs, and whose values are the names of the modified files
      # (solution, spec, or both).
      # @return [Hash{Array(String, String), Array<String>}]
      def self.modified_puzzles
        output = `git status -su | grep -e "^ M src" -e "^ M spec" -e "^M  src" -e "^M  spec"`
        filenames = output.scan(/(?:src|spec)\/\d{4}\/\d\d(?:_spec)?.rb/).uniq
        filenames.group_by { |filename|
          filename
            .match(/(?<year>\d{4})\/(?<day>\d\d)(?:_spec)?.rb$/)
            .captures
        }
      end

      # Year and day of the latest-date solution in the most recent commit, or nil.
      # @return [Array(String, String), nil]
      def self.last_committed_puzzle(year: nil, exclude_year: nil)
        if exclude_year
          output = `git log -n 1 --diff-filter=A --name-only --pretty=format: -- src spec ':!src/#{exclude_year}' ':!spec/#{exclude_year}'`
        elsif year && !Dir.exist?(File.join("src", year))
          return nil
        else
          output = `git log -n 1 --diff-filter=A --name-only --pretty=format: #{File.join("src", year || "")} #{File.join("spec", year || "")}`
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

        previous_days = (2015..Date.today.year - 1).map { [it, (1..25).to_a] }.to_h
        if Date.today.month == 12
          previous_days[Date.today.year] = (1..Date.today.day)
        end

        committed_days = committed_solution_files
          .split("\n")
          .reject(&:empty?)
          .map {
            match = it.match(/(?<year>\d{4})\/(?<day>\d\d).rb$/)
            year, day = match[:year], match[:day]
            [year.to_i, day.to_i]
          }
          .group_by(&:first)
          .transform_values { it.map(&:last) }

        previous_days.map { |year, days|
          days_hash = days.map { |day|
            [
              day.to_s.rjust(2, "0"),
              committed_days.has_key?(year) && committed_days[year].include?(day)
            ]
          }.to_h

          [year.to_s, days_hash]
        }.to_h
      end

      # @return [Boolean]
      def self.repo_exists?
        `git rev-parse --is-inside-work-tree 2> /dev/null`.chomp == "true"
      end

      def self.init!
        `git init`
      end

      def self.commit!(filenames:, message:)
        `git add #{filenames.join(" ")}`
        `git commit -m "#{message}"`
      end

      def self.commit_all!(message:)
        `git add -A`
        `git commit -m "#{message}"`
      end
    end
  end
end
