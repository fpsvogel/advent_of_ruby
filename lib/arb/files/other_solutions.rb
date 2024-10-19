module Arb
  module Files
    class OtherSolutions
      def self.download(year, day)
        year_directory = File.join("others", year)
        Dir.mkdir("others") unless Dir.exist?("others")
        Dir.mkdir(year_directory) unless Dir.exist?(year_directory)

        padded_day = day.rjust(2, "0")

        file_paths = %w[1 2].map do |part|
          file_path = File.join(year_directory, "#{padded_day}_#{part}.rb")

          if File.exist?(file_path)
            puts "Already exists: #{file_path}"
          else
            other_solutions = Api::OtherSolutions.new.other_solutions(year, day, part)
            File.write(file_path, other_solutions)
          end

          file_path
        end

        file_paths
      end
    end
  end
end
