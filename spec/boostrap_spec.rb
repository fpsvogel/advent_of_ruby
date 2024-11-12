require "arb/arb"
require "working_dir_file_creating"

describe Arb::Cli do
  include WorkingDirFileCreating

  describe "::bootstrap" do
    context "when no working directory files exist" do
      it "asks the user for initial config questions, then creates files, then downloads the puzzle", vcr: "bootstrap_2019_01" do
        year, day = "2019", "1"
        input_year, input_day = nil, nil

        create_working_dir!(create_files: false)

        expect_puzzle_files_will_be_opened_in_editor(year:, day:)
        expect(STDIN).to receive(:gets).once.and_return("\n") # accept default editor
        expect(STDIN).to receive(:gets).once.and_return("stubbed_session_cookie\n")
        expect(STDIN).to receive(:gets).once.and_return("2019\n") # year to start with

        expect {
          Arb::Cli.bootstrap(year: input_year, day: input_day)
        }.to output(
          include("✅ Initial files created and committed to a new Git repository.")
          .and include("🤘 Bootstrapped 2019#1")
        ).to_stdout

        expect_puzzle_files_to_have_correct_contents(year:, day:)
        expect_working_dir_files_to_have_correct_contents
      ensure
        remove_working_dir!
      end
    end

    context "when all working directory files and a previously solved puzzle already exist" do
      it "downloads the next puzzle", vcr: "bootstrap_2019_02" do
        year, day = "2019", "2"
        input_year, input_day = nil, nil

        create_working_dir!
        create_fake_solutions!(year:, days: day.to_i - 1)

        expect_puzzle_files_will_be_opened_in_editor(year:, day:)

        expect {
          Arb::Cli.bootstrap(year: input_year, day: input_day)
        }.to output(
          include("🤘 Bootstrapped 2019#2")
          .and not_include("✅ Initial files created and committed to a new Git repository.")
        ).to_stdout

        expect_puzzle_files_to_have_correct_contents(year:, day:)
      ensure
        remove_working_dir!
      end
    end

    context "when a year is completed and no other year is in progress" do
      it "asks the user which year to do next, then bootstraps Day 1 of that year", vcr: "bootstrap_2019_01" do
        year, day = "2019", "1"
        input_year, input_day = nil, nil

        create_working_dir!
        create_fake_solutions!(year: "2016", days: "1".."25")

        expect_puzzle_files_will_be_opened_in_editor(year:, day:)
        expect(STDIN).to receive(:gets).once.and_return("2019\n") # year to do next

        expect {
          Arb::Cli.bootstrap(year: input_year, day: input_day)
        }.to output(
          include("🤘 Bootstrapped 2019#1")
          .and not_include("✅ Initial files created and committed to a new Git repository.")
        ).to_stdout

        expect_puzzle_files_to_have_correct_contents(year:, day:)
      ensure
        remove_working_dir!
      end
    end
  end

  context "when a year is completed and another year is in progress" do
    it "returns to the earliest in-progress year", vcr: "bootstrap_2019_02" do
      year, day = "2019", "2"
      input_year, input_day = nil, nil

      create_working_dir!
      create_fake_solutions!(year: "2016", days: "1".."25")
      create_fake_solutions!(year: "2020", days: "1")
      create_fake_solutions!(year: "2019", days: "1")

      expect_puzzle_files_will_be_opened_in_editor(year:, day:)

      expect {
        Arb::Cli.bootstrap(year: input_year, day: input_day)
      }.to output(
        include("🤘 Bootstrapped 2019#2")
        .and not_include("✅ Initial files created and committed to a new Git repository.")
      ).to_stdout

      expect_puzzle_files_to_have_correct_contents(year:, day:)
    ensure
      remove_working_dir!
    end
  end

  # File expectations

  def expect_puzzle_files_will_be_opened_in_editor(year:, day:)
    puzzle_files(year:, day:).values.each do |path|
      expect(described_class).to receive(:`).with("code #{path}").ordered
    end
  end

  def expect_puzzle_files_to_have_correct_contents(year:, day:)
    contents = puzzle_files(year:, day:).transform_values { File.read _1 }

    expect(contents.values).to all not_be_empty
    expect(contents[:instructions]).to start_with("## --- Day #{day}: ")
    expect(contents[:instructions]).to end_with("https://adventofcode.com/#{year}/day/#{day}\n")
  end

  def expect_working_dir_files_to_have_correct_contents
    working_dir_files do |filename, contents|
      if filename.include?("spec_helper")
        expect(File.read(filename)).to start_with contents
      else
        expect(File.read(filename)).to eq contents
      end

    end

    expect(`git log -n 1 --pretty=format:%s`).to eq "Initial commit"
  end

  # Files

  def puzzle_files(year:, day:)
    padded_day = day.rjust(2, "0")
    {
      others_1: File.join("others", year, "#{padded_day}_1.rb"),
      others_2: File.join("others", year, "#{padded_day}_2.rb"),
      input: File.join("input", year, "#{padded_day}.txt"),
      source: File.join("src", year, "#{padded_day}.rb"),
      spec: File.join("spec", year, "#{padded_day}_spec.rb"),
      instructions: File.join("instructions", year, "#{padded_day}.md"),
    }
  end
end
