module Arb
  module Cli
    def self.commit
      WorkingDirectory.prepare!

      change_year, change_day = Git.untracked.first
      unless change_year
        files_added = false
        change_year, change_day = Git.modified.first
      end

      first_commit = !!Git.last_committed

      if change_year
        message = "#{files_added ? "Solve" : "Improve"} #{change_year}##{change_day}"
        debugger
        Git.commit_all!(message:)

        # TODO less naive check: ensure prev. days are finished too
        if files_added && change_day == "25"
          puts "\n🎉 You've finished #{change_year}!\n\n"
        end

        if first_commit
          puts "\nNice work! When you're ready to start the next puzzle, run " \
            "`#{PASTEL.blue.bold("arb bootstrap")}` (or `arb b`).\n\n"
        end
      end
    end
  end
end
