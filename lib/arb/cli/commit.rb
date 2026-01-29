module Arb
  module Cli
    def self.commit
      WorkingDirectory.prepare!

      puzzles = Git.modified_puzzles
      if puzzles.any?
        files_modified = true
      else
        puzzles = Git.uncommitted_puzzles
      end

      if puzzles.empty?
        puts "Nothing to commit."

        if Git.commit_count <= 2
          puts
          puts "Run `#{PASTEL.blue.bold("arb bootstrap")}` (or `arb b`) to start the next puzzle."
        end

        return
      end

      puzzles.each do |(year, day), filenames|
        message = "#{files_modified ? "Improve" : "Solve"} #{year}##{day}"
        Git.commit!(filenames:, message:)

        # TODO less naive check: ensure prev. days are finished too
        if !files_modified && day == Util.max_day(year:).to_s.rjust(2, "0")
          puts
          puts "🎉 You've finished #{year}!"
          puts
        end

        puts "Puzzle #{year}##{day}#{" (modified)" if files_modified} committed 🎉"
      end

      if Git.commit_count <= 1
        puts
        puts "When you're ready to start the next puzzle, run " \
          "`#{PASTEL.blue.bold("arb bootstrap")}` (or `arb b`)."
      end
    end
  end
end
