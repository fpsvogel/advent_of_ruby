module Arb
  module Cli
    def self.commit
      WorkingDirectory.prepare!

      change_year, change_day = Git.uncommitted_solutions.first
      unless change_year
        files_modified = true
        change_year, change_day = Git.modified_solutions.first
      end

      unless change_year
        puts "Nothing to commit."

        if Git.commit_count <= 2
          puts "\nRun `#{PASTEL.blue.bold("arb bootstrap")}` (or `arb b`) to start the next puzzle."
        end

        return
      end

      message = "#{files_modified ? "Improve" : "Solve"} #{change_year}##{change_day}"
      Git.commit_all!(message:)

      # TODO less naive check: ensure prev. days are finished too
      if !files_modified && change_day == "25"
        puts "\n🎉 You've finished #{change_year}!\n\n"
      end

      if Git.commit_count <= 1
        puts "Solution committed! When you're ready to start the next puzzle, run " \
          "`#{PASTEL.blue.bold("arb bootstrap")}` (or `arb b`)."
      end
    end
  end
end
