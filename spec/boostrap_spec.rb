require "arb/arb"
require "working_dir_file_creating"

describe Arb::Cli do
  include WorkingDirFileCreating

  describe "::bootstrap" do
    context "when no working directory files exist" do
      it "asks the user for initial config questions, then creates files, then downloads the puzzle", vcr: "bootstrap_2019_01" do
        year, day = "2019", "1"
        input_year, input_day = nil, nil

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)

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
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end

    context "when all working directory files and a previously solved puzzle already exist" do
      it "downloads the next puzzle", vcr: "bootstrap_2019_02" do
        year, day = "2019", "2"
        input_year, input_day = nil, nil

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)
        create_working_dir_files!
        create_fake_solution!(year:, day: (day.to_i - 1).to_s)

        expect_puzzle_files_will_be_opened_in_editor(year:, day:)

        expect {
          Arb::Cli.bootstrap(year: input_year, day: input_day)
        }.to output(include("🤘 Bootstrapped 2019#2")).to_stdout
        .and not_output(include("✅ Initial files created and committed to a new Git repository.")).to_stdout

        expect_puzzle_files_to_have_correct_contents(year:, day:)
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end

    context "when a year is completed and no other year is in progress" do
      it "asks the user which year to do next, then bootstraps Day 1 of that year", vcr: "bootstrap_2019_01" do
        year, day = "2019", "1"
        input_year, input_day = nil, nil

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)
        create_working_dir_files!
        25.times do |index|
          create_fake_solution!(year: "2016", day: (index + 1).to_s)
        end

        expect_puzzle_files_will_be_opened_in_editor(year:, day:)
        expect(STDIN).to receive(:gets).once.and_return("2019\n") # year to do next

        expect {
          Arb::Cli.bootstrap(year: input_year, day: input_day)
        }.to output(include("🤘 Bootstrapped 2019#1")).to_stdout
        .and not_output(include("✅ Initial files created and committed to a new Git repository.")).to_stdout

        expect_puzzle_files_to_have_correct_contents(year:, day:)
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end
  end

  context "when a year is completed and another year is in progress" do
    it "returns to the earliest in-progress year", vcr: "bootstrap_2019_02" do
      year, day = "2019", "2"
      input_year, input_day = nil, nil

      working_dir, original_dir = create_working_dir!
      Dir.chdir(working_dir)
      create_working_dir_files!
      25.times do |index|
        create_fake_solution!(year: "2016", day: (index + 1).to_s)
      end
      create_fake_solution!(year: "2020", day: "1")
      create_fake_solution!(year: "2019", day: "1")

      expect_puzzle_files_will_be_opened_in_editor(year:, day:)

      expect {
        Arb::Cli.bootstrap(year: input_year, day: input_day)
      }.to output(include("🤘 Bootstrapped 2019#2")).to_stdout
      .and not_output(include("✅ Initial files created and committed to a new Git repository.")).to_stdout

      expect_puzzle_files_to_have_correct_contents(year:, day:)
    ensure
      Dir.chdir(original_dir)
      `rm -rf #{working_dir}`
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

  def create_fake_solution!(year:, day:)
    Dir.mkdir(File.join("src", year)) unless Dir.exist?(File.join("src", year))
    Dir.mkdir(File.join("spec", year)) unless Dir.exist?(File.join("spec", year))

    padded_day = day.rjust(2, "0")
    File.write(File.join("src", year, "#{padded_day}.rb"), "a fake solution")
    File.write(File.join("spec", year, "#{padded_day}_spec.rb"), "a fake spec")

    `git add -A`
    `git commit -m "Solve #{year}##{padded_day}"`
  end
end
