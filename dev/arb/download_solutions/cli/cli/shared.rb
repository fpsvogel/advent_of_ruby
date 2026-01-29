module Arb
  module DownloadSolutions
    module Cli
      private_class_method def self.output_initial_message(source:, year:, day:, force:, detail:)
        force_description = PASTEL.red("FORCE ") if force
        year_description = year.nil? ? "all years" : year.to_s
        day_description = day.nil? ? "" : "##{day.to_s.rjust(2, "0")}"
        time_description = PASTEL.blue("#{year_description}#{day_description}")

        puts "#{force_description}Downloading #{source} solutions from #{time_description} #{detail}..."
        puts
      end
    end
  end
end
