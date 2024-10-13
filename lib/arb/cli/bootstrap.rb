module Arb
  module Cli
    # @param year [String]
    # @param day [String]
    def self.bootstrap(year, day)
      Shared::WorkingDirectory.prepare!

      year, day = Shared::YearDayValidator.validate_year_and_day(year, day)

      git_commit

      input_path = Files::Input.download(year, day)
      instructions_path = Files::Instructions.download(year, day)
      source_path = Files::Source.create(year, day)
      spec_path = Files::Spec.create(year, day)
      others_1_path, others_2_path = Files::OtherSolutions.download(year, day)

      puts "🤘 Bootstrapped #{year}##{day}\n\n"

      # Open the new files.
      `#{ENV["EDITOR_COMMAND"]} #{others_1_path}`
      `#{ENV["EDITOR_COMMAND"]} #{others_2_path}`
      `#{ENV["EDITOR_COMMAND"]} #{input_path}`
      `#{ENV["EDITOR_COMMAND"]} #{source_path}`
      `#{ENV["EDITOR_COMMAND"]} #{spec_path}`
      `#{ENV["EDITOR_COMMAND"]} #{instructions_path}`

      last_committed_solution = `git log -n 1 --diff-filter=A --name-only --pretty=format: #{File.join("src", year || "")}`.lines.last
      if !last_committed_solution
        puts "Now fill in the spec for Part One with an example from the instructions, " \
          "then run it with `#{PASTEL.blue.bold("arb run")}` (or just `arb`) as " \
          "you implement the solution. When the spec passes, your solution will " \
          "be run with the real input and you'll be prompted to submit your solution.\n"
      end
    rescue AppError => e
      puts Pastel.new.red(e.message)
    end
  end
end
