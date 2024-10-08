module Arb
  class OtherSolutionsFiles
    def self.download(year, day)
      year_directory = File.join("others", year)
      Dir.mkdir(year_directory) if !Dir.exist?(year_directory)

      padded_day = day.rjust(2, "0")
      year_last_two = year[-2..]

      file_paths = %w[1 2].map do |part|
        file_path = File.join(year_directory, "#{padded_day}_#{part}.rb")

        if File.exist?(file_path)
          puts "Already exists: #{file_path}"
        else
          other_solutions = OtherSolutionsApi.new.other_solutions(year, day, part)
          File.write(file_path, other_solutions)
        end

        file_path
      end

      file_paths
    end
  end
end
