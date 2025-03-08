require "download_solutions/download_solutions"
require "download_solutions/spec_working_dir"

describe DownloadSolutions::Cli do
  include DownloadSolutions::SpecWorkingDir

  describe "::reddit" do
    before(:all) do
      create_working_dir!
    end

    after(:all) do
      remove_working_dir!
    end

    def download_solutions(year:, day:)
      day_str = day.to_s.rjust(2, "0")

      expect {
        DownloadSolutions::Cli.reddit(year:, day:)
      }.to output(
        include_ignoring_colors_and_spacing("Downloading Reddit solutions from #{year}##{day_str} for ruby...")
        .and include_ignoring_colors_and_spacing("Fetching comments for #{year}##{day_str}...")
        .and include_ignoring_colors_and_spacing("Saved #{year}##{day_str} to data/solutions/reddit/ruby/#{year}/#{day_str}.yml")
      ).to_stdout

      file_path = File.join("data", "solutions", "reddit", "ruby", year.to_s, "#{day_str}.yml")
      existing_file_contents = File.read(File.join(@original_dir, file_path))
      new_file_contents = File.read(File.join(file_path))

      expect(new_file_contents).to eq(existing_file_contents)
    end

    context "2024#01", vcr: "reddit_2024_01" do
      it { download_solutions(year: 2024, day: 1) }
    end

    context "2023#01", vcr: "reddit_2023_01" do
      it { download_solutions(year: 2023, day: 1) }
    end

    context "2022#01", vcr: "reddit_2022_01" do
      it { download_solutions(year: 2022, day: 1) }
    end

    context "2021#01", vcr: "reddit_2021_01" do
      it { download_solutions(year: 2021, day: 1) }
    end
  end
end
