module Arb
  module Cli
    class Git
      # Years and days of uncommitted new solutions, or an empty array.
      # @param year [String, Integer]
      # @return [Array<Array(String, String)>]
      def self.new_solutions(year: nil)
        output = `git status -su | grep -e "^?? #{File.join("src", year || "")}" -e "^?? #{File.join("spec", year || "")}" -e "^A  #{File.join("src", year || "")}" -e "^A  #{File.join("spec", year || "")}"`
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
        output =
          if exclude_year
            `git log -n 1 --diff-filter=A --name-only --pretty=format: -- src spec ':!src/#{exclude_year}' ':!spec/#{exclude_year}'`
          else
            `git log -n 1 --diff-filter=A --name-only --pretty=format: #{File.join("src", year || "")} #{File.join("spec", year || "")}`
          end

        return nil if output.empty?

        output.scan(/(?<year>\d{4})\/(?<day>\d\d)(?:_spec)?.rb$/).last
      end

      # Counts of committed .rb files in the given directory, grouped by subdirectory.
      # @return [Hash{String => Integer}]
      def self.count_by_subdirs(dir:)
        `git ls-files #{dir}`
          .split("\n")
          .select { |path| File.basename(path).match?(/\d\d\.rb/) }
          .group_by { |path| File.basename(File.dirname(path)) }
          .transform_values(&:count)
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
