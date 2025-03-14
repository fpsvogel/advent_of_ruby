module DownloadSolutions
  module Cli
    private_class_method def self.validate_year_and_day(year:, day:)
      if day
        if year.nil?
          raise InputError, "Year must be specified when day is specified."
        end
        if !day.between?(1, 25) && Date.new(year, 12, day) > Date.today
          raise InputError, "Day must be between 1 and 25, and <= today."
        end
      end
      if year && !year.between?(2015, Date.today.year)
        raise InputError, "Year must be between 2015 and this year."
      end
    end

    private_class_method def self.max_year_and_day(year:, day:)
      if Date.today.year == year && Date.today.month == 12
        [Date.today.year, Date.today.day]
      else
        [Date.today.year - 1, 25]
      end
    end

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
