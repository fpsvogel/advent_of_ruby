require "arb/arb"
require "working_dir_file_creating"

describe Arb::Cli do
  include WorkingDirFileCreating

  describe "::run" do
    context "when a puzzle has just been bootstrapped" do
      it "runs Part One specs" do
        year, day = "2019", "1"
        padded_day = day.rjust(2, "0")
        input_year, input_day = nil, nil

        rspec_partial_output = <<~OUT
          F*

          Pending: (Failures listed here are expected and do not affect your suite's status)

            1) Year#{year}::Day#{padded_day} solves Part Two
               # Temporarily skipped with xit
               # ./spec/#{year}/#{padded_day}_spec.rb:14

          Failures:

            1) Year#{year}::Day#{padded_day} solves Part One
               Failure/Error: expect(subject.part_1(input)).to eq(:todo)

                 expected: :todo
                      got: nil

                 (compared using ==)
               # ./spec/#{year}/#{padded_day}_spec.rb:11:in `block (2 levels) in <top (required)>'
        OUT

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)
        create_working_dir_files!
        create_puzzle!(year:, day:)

        expect {
          Arb::Cli.run(year: input_year, day: input_day, options: {})
        }.to output(include_ignoring_colors_and_spacing(rspec_partial_output)).to_stdout_from_any_process
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end

    context "when Part One has been solved" do
      it "runs Part One and prompts to submit it", vcr: "run_2019_01_1" do
        # instructions_file_path = File.join("instructions", year, "#{day.rjust(2, "0")}.md")
        # expect(described_class).to receive(:`).with("code #{instructions_file_path}").ordered
      end
    end

    context "when Part Two has been solved" do
      it "runs Part Two and prompts to submit it", vcr: "run_2019_01_2" do

      end
    end

    context "when both parts have been solved" do
      it "runs both parts" do

      end
    end

    context "when both parts have been committed" do
      it "runs both parts" do

      end
    end

    context "with --spec flag" do
      it "runs only specs" do

      end
    end

    context "with --one flag" do
      it "runs only Part One" do

      end
    end

    context "with --two flag" do
      it "runs only Part Two" do

      end
    end
  end

  def create_puzzle!(year:, day:)
    padded_day = day.rjust(2, "0")

    Dir.mkdir("instructions")
    Dir.mkdir(File.join("instructions", year))
    File.write(File.join("instructions", year, "#{padded_day}.md"), "## Day 1\n\nSome instructions.")

    Dir.mkdir("input")
    Dir.mkdir(File.join("input", year))
    File.write(File.join("input", year, "#{padded_day}.txt"), "")

    Dir.mkdir(File.join("src", year))
    File.write(File.join("src", year, "#{padded_day}.rb"), Arb::Files::Source.source(year, day))

    Dir.mkdir(File.join("spec", year))
    File.write(File.join("spec", year, "#{padded_day}_spec.rb"), Arb::Files::Spec.source(year, day))
  end
end
