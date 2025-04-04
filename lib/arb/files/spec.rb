module Arb
  module Files
    class Spec
      def self.create(year:, day:, notify_exists: true)
        year_directory = File.join("spec", year)
        Dir.mkdir(year_directory) unless Dir.exist?(year_directory)

        file_path = File.join(year_directory, "#{day}_spec.rb")

        if File.exist?(file_path)
          puts "Already exists: #{file_path}" if notify_exists
        else
          File.write(file_path, template(year:, day:))
        end

        Formatter.format(file_path)

        file_path
      end

      def self.template(year:, day:)
        <<~SPECS
          RSpec.describe Year#{year}::Day#{day} do
            let(:input) {
              StringIO.new(
                <<~IN
                  something
                IN
              )
            }

            it "solves Part One" do
              expect(subject.part_1(input)).to eq(:todo)
            end

            xit "solves Part Two" do
              expect(subject.part_2(input)).to eq(:todo)
            end
          end
        SPECS
      end
    end
  end
end
