module Arb
  module Cli
    def self.commit
      WorkingDirectory.prepare!

      change_year, change_day = Git.new_solutions.first
      unless change_year
        files_modified = true
        change_year, change_day = Git.modified_solutions.first
      end

      first_commit = !!Git.last_committed_solution

      if change_year
        message = "#{files_modified ? "Improve" : "Solve"} #{change_year}##{change_day}"
        Git.commit_all!(message:)

        # TODO less naive check: ensure prev. days are finished too
        if !files_modified && change_day == "25"
          puts "\n🎉 You've finished #{change_year}!\n\n"
        end

        if first_commit
          puts "\nSolution committed! When you're ready to start the next puzzle, run " \
            "`#{PASTEL.blue.bold("arb bootstrap")}` (or `arb b`).\n\n"
        end
      end
    end
  end
end
