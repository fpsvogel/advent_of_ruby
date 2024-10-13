module Arb
  module Cli
    def self.git_commit
      Shared::WorkingDirectory.prepare!

      # TODO extract this etc. into a Git interface
      changes = `git status -su | grep -e "^?? src" -e "^?? spec"`
      files_added = !changes.empty?
      if changes.empty?
        changes = `git status -su | grep -e "^ M src" -e "^ M spec"`
      end
      change_year, change_day = nil, nil
      unless changes.empty?
        match = changes.match(/(?<year>\d{4})\/(?<day>\d\d)(?:_spec)?.rb$/)
        change_year, change_day = match[:year], match[:day]
        `git add -A`
        `git commit -m "#{files_added ? "Solve" : "Improve"} #{change_year}##{change_day}"`

        if files_added && change_day == "25"
          puts "\n🎉 You've finished #{change_year}!\n\n"
        end
      end
    end
  end
end
