module Arb
  module Util
    def self.years_and_max_days
      return @years_and_max_days if @years_and_max_days

      max_year =
        if Date.today.month == 12
          Date.today.year
        else
          Date.today.year - 1
        end

      @years_and_max_days = (2015..max_year).map { |year|
        max_day = max_day(year:)

        if year == Date.today.year
          [year, Date.today.day.clamp(0..max_day)]
        else
          [year, max_day]
        end
      }.to_h
    end

    def self.max_day(year:)
      (year.to_i >= 2025) ? 12 : 25 # only 12 days starting in 2025
    end

    def self.validate_year_and_day(year:, day:)
      if year < years_and_max_days.keys.first
        raise InputError, "Year must be at least 2015, when Advent of Code started."
      end
      if year > years_and_max_days.keys.last
        raise InputError, "Advent of Code #{year} is still in the future."
      end
      if Date.new(year, 12, day) > Date.today
        raise InputError, "Day must be <= today."
      end
      if !day.between?(1, years_and_max_days[year])
        raise InputError, "For #{year}, day must be between 1 and #{years_and_max_days[year]}."
      end
    end
  end
end
