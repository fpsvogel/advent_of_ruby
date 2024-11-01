require "arb/arb"

describe Arb::Cli do
  describe "::bootstrap" do
    context "when no working directory files exist" do
      it "prompts the user for initial config, then creates files, then downloads the puzzle", vcr: "bootstrap_2019_01" do
        year, day = "2019", "1"
        input_year, input_day = nil, nil

        temp_dir, original_dir = create_temp_dir!
        Dir.chdir(temp_dir)

        expect_puzzle_files_will_be_opened_in_editor(year:, day:)
        expect(STDIN).to receive(:gets).once.and_return("\n")
        expect(STDIN).to receive(:gets).once.and_return("stubbed_session_cookie\n")
        expect(STDIN).to receive(:gets).once.and_return("2019\n")

        expect {
          Arb::Cli.bootstrap(year: input_year, day: input_day)
        }.to output(
          match("✅ Initial files created and committed to a new Git repository.")
          .and match("🤘 Bootstrapped 2019#1")
        ).to_stdout

        expect_puzzle_files_to_have_correct_contents(year:, day:)
        expect_working_directory_files_to_have_correct_contents
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{temp_dir}`
      end
    end

    context "when all working directory files and a previously solved puzzle already exist" do
      it "downloads the next puzzle", vcr: "bootstrap_2019_02" do
        year, day = "2019", "2"
        input_year, input_day = nil, nil

        temp_dir, original_dir = create_temp_dir!
        Dir.chdir(temp_dir)
        create_working_directory_files!
        create_previous_puzzle!(year:, day:)

        expect_puzzle_files_will_be_opened_in_editor(year:, day:)

        expect {
          Arb::Cli.bootstrap(year: input_year, day: input_day)
        }.to output(match("🤘 Bootstrapped 2019#2")).to_stdout
        .and not_output(match("✅ Initial files created and committed to a new Git repository.")).to_stdout

        expect_puzzle_files_to_have_correct_contents(year:, day:)
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{temp_dir}`
      end
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

  def expect_working_directory_files_to_have_correct_contents
    self.class.working_directory_files do |filename, contents|
      if filename.include?("spec_helper")
        expect(File.read(filename)).to start_with contents
      else
        expect(File.read(filename)).to eq contents
      end

    end

    expect(`git log -n 1 --pretty=format:%s`).to eq "Initial commit"
  end

  # File paths and contents

  def self.working_directory_files
    @working_directory_files = {
      ".env" => <<~FILE.chomp,
        EDITOR_COMMAND=code
        AOC_COOKIE=stubbed_session_cookie
      FILE
      **Arb::Cli::WorkingDirectory::FILES,
      ".rspec" => "--require spec_helper\n",
    }
  end

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

  # Directory and file creation

  def create_temp_dir!
    original_dir = Dir.pwd
    temp_dir = File.join(Dir.home, "arb_temp")

    if Dir.exist?(temp_dir)
      `rm -rf #{temp_dir}`
    end

    Dir.mkdir(temp_dir)

    [temp_dir, original_dir]
  end

  def create_working_directory_files!
    Dir.mkdir("src")
    Dir.mkdir("spec")

    self.class.working_directory_files.each do |filename, contents|
      File.write(filename, contents)
    end

    `git init`
    `git add -A`
    `git commit -m "Initial commit"`
  end

  def create_previous_puzzle!(year:, day:)
    prev_day = (day.to_i - 1).to_s.rjust(2, "0")

    Dir.mkdir(File.join("src", year))
    Dir.mkdir(File.join("spec", year))

    File.write(File.join("src", year, "#{prev_day}.rb"), "a fake solution")
    File.write(File.join("spec", year, "#{prev_day}_spec.rb"), "a fake spec")

    `git add -A`
    `git commit -m "Solve 2019#01"`
  end
end
