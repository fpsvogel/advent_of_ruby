module Arb
  module Cli
    def self.progress
      WorkingDirectory.prepare!

      past_year_count = 25 * (Date.today.year - 1 - 2015)
      this_year_count = (Date.today.month == 12 ? Date.today.day : 0).clamp(..25)
      total_count = past_year_count + this_year_count

      my_counts_by_year = Git.count_by_subdirs(dir: "src")
      my_total_count = my_counts_by_year.values.sum

      total_percent = (my_total_count.to_f / total_count * 100).round(1)
      total_percent == total_percent.to_i ? total_percent.to_i : total_percent

      puts "You have completed:\n\n"
      puts PASTEL.bold "#{PASTEL.blue("All:")}\t#{total_percent}% \t#{my_total_count}/#{total_count} puzzles\n"

      my_counts_by_year.each do |year, my_count|
        if year.to_i == Date.today.year
          year_count = this_year_count
        else
          year_count = 25
        end

        year_percent = (my_count.to_f / year_count * 100).round

        puts "#{PASTEL.blue(year + ":")}\t#{year_percent}%\t#{my_count}/#{year_count}"
      end
    end
  end
end
