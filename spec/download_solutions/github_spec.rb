require "download_solutions/download_solutions"
require "download_solutions/spec_working_dir"

describe DownloadSolutions::Cli do
  include DownloadSolutions::SpecWorkingDir

  describe "::github" do
    before(:all) do
      create_working_dir!(service: :github)
    end

    after(:all) do
      remove_working_dir!
    end

    def download_solutions(author:, year:)
      days_and_parts = (1..25).flat_map { |day|
        [[day, 1], ([day, 2] unless day == 25)]
      }.compact

      expect {
        DownloadSolutions::Cli.github(year:)
      }.to output(
        include_ignoring_colors_and_spacing("Downloading GitHub solutions from #{year} by all authors...")
      ).to_stdout

      year_dir = File.join("data", "solutions", "github", author, year.to_s)
      if !Dir.exist?(year_dir)
        expect(Dir.exist?(File.join(@original_dir, year_dir))).to be false
        return
      end

      days_and_parts.each do |day, part|
        filename = "#{day.to_s.rjust(2, "0")}_#{part}.yml"
        existing_file_contents = File.read(File.join(@original_dir, year_dir, filename))
        new_file_contents = File.read(File.join(year_dir, filename))

        expect(new_file_contents).to eq(existing_file_contents)
      end
    end

    %w[ahorner erergon erikw gchan ZogStriP].each do |author|
      context "#{author} 2023", vcr: "github_#{author}_2023" do
        it { download_solutions(author:, year: 2023) }
      end
    end
  end
end
