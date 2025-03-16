module Arb
  module Files
    class OtherSolutions
      def self.download(year:, day:)
        year_directory = File.join("others", year)
        Dir.mkdir("others") unless Dir.exist?("others")
        Dir.mkdir(year_directory) unless Dir.exist?(year_directory)

        %w[1 2].map do |part|
          file_path = File.join(year_directory, "#{day}_#{part}.md")

          if File.exist?(file_path)
            puts "Already exists: #{file_path}"
          else
            other_solutions = Api::OtherSolutions.new(year:, day:, part:).other_solutions
            File.write(file_path, other_solutions)
          end

          file_path
        end
      end
    end
  end
end
