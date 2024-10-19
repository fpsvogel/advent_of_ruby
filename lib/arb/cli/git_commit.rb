module Arb
  module Cli
    def self.git_commit
      WorkingDirectory.prepare!

      change_year, change_day = Git.untracked.first
      unless change_year
        files_added = false
        change_year, change_day = Git.modified.first
      end

      if change_year
        message = "#{files_added ? "Solve" : "Improve"} #{change_year}##{change_day}"
        Git.commit_all!(message:)

        if files_added && change_day == "25"
          puts "\n🎉 You've finished #{change_year}!\n\n"
        end
      end
    end
  end
end
