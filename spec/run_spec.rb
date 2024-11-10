require "arb/arb"
require "working_dir_file_creating"

describe Arb::Cli do
  include WorkingDirFileCreating

  describe "::run" do
    context "when a puzzle has just been bootstrapped" do
      it "runs Part One specs" do
        year, day = "2017", "1"
        padded_day = day.rjust(2, "0")
        input_year, input_day = nil, nil

        rspec_output = <<~OUT
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
        }.to output(
          include_ignoring_colors_and_spacing(rspec_output)
        ).to_stdout_from_any_process
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end

    context "when Part One has been solved" do
      it "runs Part One and prompts to submit it", vcr: "run_2017_01_1" do
        year, day = "2017", "1"
        padded_day = day.rjust(2, "0")
        input_year, input_day = nil, nil
        input = input_for_2017_01

        run_results_output = <<~OUT
          Specs passed!

          Result for 2017#1.1:
          1182
        OUT
        submit_prompt_output = "Submit solution? (Y/n)"
        correct_answer_output = "That's the right answer! You are one gold star closer to debugging the printer."
        redownloaded_instructions_output = "Downloaded instructions for Part Two."

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)
        create_working_dir_files!
        create_puzzle!(year:, day:, input:, **solution_and_spec_for_2017_01_1)

        expect(STDIN).to receive(:gets).once.and_return("\n") # default "Y" to submit

        instructions_file_path = File.join("instructions", year, "#{padded_day}.md")
        expect(described_class).to receive(:`).with("code #{instructions_file_path}")

        expect {
          Arb::Cli.run(year: input_year, day: input_day, options: {})
        }.to output(
          include_ignoring_colors_and_spacing(run_results_output)
          .and include(submit_prompt_output)
          .and include(correct_answer_output)
          .and include(redownloaded_instructions_output)
        ).to_stdout

        expect_instructions_file_to_have_been_redownloaded(year:, day:)
        expect_part_two_spec_to_have_been_unskipped(year:, day:)
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end

    context "when Part Two has been solved" do
      it "runs Part Two and prompts to submit it", vcr: "run_2017_01_2" do
        year, day = "2017", "1"
        input_year, input_day = nil, nil
        input = input_for_2017_01

        run_results_output = <<~OUT
          Specs passed!

          Result for 2017#1.2:
          1152
        OUT
        submit_prompt_output = "Submit solution? (Y/n)"
        correct_answer_output = "That's the right answer! You are one gold star closer to debugging the printer."

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)
        create_working_dir_files!
        create_puzzle!(year:, day:, submitted_answers: [1182], input:, **solution_and_spec_for_2017_01_2)

        expect(STDIN).to receive(:gets).once.and_return("\n") # default "Y" to submit

        expect {
          Arb::Cli.run(year: input_year, day: input_day, options: {})
        }.to output(
          include_ignoring_colors_and_spacing(run_results_output)
          .and include(submit_prompt_output)
          .and include(correct_answer_output)
        ).to_stdout
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end

    context "when both parts have been solved" do
      it "runs both parts" do
        year, day = "2017", "1"
        input_year, input_day = nil, nil
        input = input_for_2017_01

        run_results_output_part_1 = <<~OUT
          Specs passed!

          Result for 2017#1.1:
          ✅ 1182
        OUT
        run_results_output_part_2 = <<~OUT
          Result for 2017#1.2:
          ✅ 1152
        OUT
        already_submitted_output = "You've already submitted the answers to both parts."

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)
        create_working_dir_files!
        create_puzzle!(year:, day:, submitted_answers: [1182, 1152], input:, **solution_and_spec_for_2017_01_2)

        expect {
          Arb::Cli.run(year: input_year, day: input_day, options: {})
        }.to output(
          include_ignoring_colors_and_spacing(run_results_output_part_1)
          .and include_ignoring_colors_and_spacing(run_results_output_part_2)
          .and include(already_submitted_output)
        ).to_stdout
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end

    context "when both parts have been committed" do
      it "runs both parts" do
        year, day = "2017", "1"
        input_year, input_day = nil, nil
        input = input_for_2017_01

        run_results_output_part_1 = <<~OUT
          Specs passed!

          Result for 2017#1.1:
          ✅ 1182
        OUT
        run_results_output_part_2 = <<~OUT
          Result for 2017#1.2:
          ✅ 1152
        OUT
        already_submitted_output = "You've already submitted the answers to both parts."

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)
        create_working_dir_files!
        create_puzzle!(year:, day:, submitted_answers: [1182, 1152], input:, **solution_and_spec_for_2017_01_2, git_commit: true)

        expect {
          Arb::Cli.run(year: input_year, day: input_day, options: {})
        }.to output(
          include_ignoring_colors_and_spacing(run_results_output_part_1)
          .and include_ignoring_colors_and_spacing(run_results_output_part_2)
          .and include(already_submitted_output)
        ).to_stdout
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end

    context "with --spec flag" do
      it "runs only specs" do
        year, day = "2017", "1"
        input_year, input_day = nil, nil
        input = input_for_2017_01

        rspec_output = "2 examples, 0 failures"
        run_results_not_output_part_1 = <<~OUT
          Result for 2017#1.1:
          ✅ 1182
        OUT
        run_results_not_output_part_2 = <<~OUT
          Result for 2017#1.2:
          ✅ 1152
        OUT

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)
        create_working_dir_files!
        create_puzzle!(year:, day:, submitted_answers: [1182, 1152], input:, **solution_and_spec_for_2017_01_2)

        expect {
          Arb::Cli.run(year: input_year, day: input_day, options: {spec: true})
        }.to output(
          include(rspec_output)
          .and not_include_ignoring_colors_and_spacing(run_results_not_output_part_1)
          .and not_include_ignoring_colors_and_spacing(run_results_not_output_part_2)
        ).to_stdout_from_any_process
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end

    context "with --one flag" do
      it "runs only Part One" do
        year, day = "2017", "1"
        input_year, input_day = nil, nil
        input = input_for_2017_01

        run_results_output = <<~OUT
          Result for 2017#1.1:
          ✅ 1182
        OUT
        already_submitted_output = "You've already submitted the answers to both parts."
        specs_passed_not_output = "Specs passed!"
        run_results_not_output_other_part = <<~OUT
          Result for 2017#1.2:
          ✅ 1152
        OUT

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)
        create_working_dir_files!
        create_puzzle!(year:, day:, submitted_answers: [1182, 1152], input:, **solution_and_spec_for_2017_01_2)

        expect {
          Arb::Cli.run(year: input_year, day: input_day, options: {one: true})
        }.to output(
          include_ignoring_colors_and_spacing(run_results_output)
          .and include(already_submitted_output)
          .and not_include_ignoring_colors_and_spacing(specs_passed_not_output)
          .and not_include_ignoring_colors_and_spacing(run_results_not_output_other_part)
        ).to_stdout
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end

    context "with --two flag" do
      it "runs only Part Two" do
        year, day = "2017", "1"
        input_year, input_day = nil, nil
        input = input_for_2017_01

        run_results_output = <<~OUT
          Result for 2017#1.2:
          ✅ 1152
        OUT
        already_submitted_output = "You've already submitted the answers to both parts."
        specs_passed_not_output = "Specs passed!"
        run_results_not_output_other_part = <<~OUT
          Result for 2017#1.1:
          ✅ 1182
        OUT

        working_dir, original_dir = create_working_dir!
        Dir.chdir(working_dir)
        create_working_dir_files!
        create_puzzle!(year:, day:, submitted_answers: [1182, 1152], input:, **solution_and_spec_for_2017_01_2)

        expect {
          Arb::Cli.run(year: input_year, day: input_day, options: {two: true})
        }.to output(
          include_ignoring_colors_and_spacing(run_results_output)
          .and include(already_submitted_output)
          .and not_include_ignoring_colors_and_spacing(specs_passed_not_output)
          .and not_include_ignoring_colors_and_spacing(run_results_not_output_other_part)
        ).to_stdout
      ensure
        Dir.chdir(original_dir)
        `rm -rf #{working_dir}`
      end
    end
  end

  # File expectations

  def expect_instructions_file_to_have_been_redownloaded(year:, day:)
    padded_day = day.rjust(2, "0")
    instructions = File.read(File.join("instructions", year, "#{padded_day}.md"))
    expect(instructions).to include("## --- Part Two ---")
  end

  def expect_part_two_spec_to_have_been_unskipped(year:, day:)
    padded_day = day.rjust(2, "0")
    spec_file = File.read(File.join("spec", year, "#{padded_day}_spec.rb"))
    expect(spec_file).to include(/^\s*it "solves Part Two" do/)
  end

  # File creation/editing

  def create_puzzle!(year:, day:, submitted_answers: [], input: "", solution: nil, spec: nil, git_commit: false)
    padded_day = day.rjust(2, "0")

    instructions = "## Day 1\n\nSome instructions.\n"
    submitted_answers.each do |answer|
      instructions << "\nYour puzzle answer was `#{answer}`.\n"
    end
    Dir.mkdir("instructions")
    Dir.mkdir(File.join("instructions", year))
    File.write(File.join("instructions", year, "#{padded_day}.md"), instructions)

    Dir.mkdir("input")
    Dir.mkdir(File.join("input", year))
    File.write(File.join("input", year, "#{padded_day}.txt"), input)

    Dir.mkdir(File.join("src", year))
    File.write(File.join("src", year, "#{padded_day}.rb"), solution || Arb::Files::Source.source(year, day))
    load "#{Dir.pwd}/src/#{year}/#{padded_day}.rb"

    Dir.mkdir(File.join("spec", year))
    File.write(File.join("spec", year, "#{padded_day}_spec.rb"), spec || Arb::Files::Spec.source(year, day))

    if git_commit
      `git add -A`
      `git commit -m "Solve #{year}##{padded_day}"`
    end
  end

  def solution_and_spec_for_2017_01_1
    solution = <<~SRC
      # https://adventofcode.com/2017/day/1
      module Year2017
        class Day01
          def part_1(input_file)
            captcha = input_file.read.chomp.chars.map(&:to_i)
              .then { [*_1, _1.first] } # append first element to simulate a circular list

            captcha
              .chunk_while { _1 == _2 }
              .map { _1.drop(1) }
              .flatten
              .sum
          end

          def part_2(input_file)
            lines = input_file.readlines(chomp: true)

            nil
          end
        end
      end
    SRC

    spec = <<~SPEC
      RSpec.describe Year2017::Day01 do
        let(:input) {
          StringIO.new(
            <<~IN
              91122111112341212129
            IN
          )
        }

        it "solves Part One" do
          expect(subject.part_1(input)).to eq(16)
        end

        xit "solves Part Two" do
          expect(subject.part_2(input)).to eq(:todo)
        end
      end
    SPEC

    {solution:, spec:}
  end

  def solution_and_spec_for_2017_01_2
    solution = <<~SRC
      # https://adventofcode.com/2017/day/1
      module Year2017
        class Day01
          def part_1(input_file)
            captcha = input_file.read.chomp.chars.map(&:to_i)
            captcha << captcha.first # simulates a circular list

            captcha
              .chunk_while { _1 == _2 }
              .map { _1.drop(1) }
              .flatten
              .sum
          end

          def part_2(input_file)
            captcha = input_file.read.chomp.chars.map(&:to_i)
            first_half, second_half = captcha.each_slice(captcha.size / 2).to_a

            first_half
              .zip(second_half)
              .filter { _1 == _2 }
              .flatten
              .sum
          end
        end
      end
    SRC

    spec = <<~SPEC
      RSpec.describe Year2017::Day01 do
        let(:input) {
          StringIO.new(
            <<~IN
              91122111112341212129
            IN
          )
        }

        it "solves Part One" do
          expect(subject.part_1(input)).to eq(16)
        end

        it "solves Part Two" do
          expect(subject.part_2(input)).to eq(8)
        end
      end
    SPEC

    {solution:, spec:}
  end

  # Other puzzle-specific info

  let(:input_for_2017_01) {
    "61697637962276641366442297247367117738114719863473648131982449728688116728695866572989524473392982963976411147683588415878214189996163533584547175794158118148724298832798898333399786561459152644144669959887341481968319172987357989785791366732849932788343772112176614723858474959919713855398876956427631354172668133549845585632211935573662181331613137869866693259374322169811683635325321597242889358147123358117774914653787371368574784376721652181792371635288376729784967526824915192526744935187989571347746222113625577963476141923187534658445615596987614385911513939292257263723518774888174635963254624769684533531443745729344341973746469326838186248448483587477563285867499956446218775232374383433921835993136463383628861115573142854358943291148766299653633195582135934544964657663198387794442443531964615169655243652696782443394639169687847463721585527947839992182415393199964893658322757634675274422993237955354185194868638454891442893935694454324235968155913963282642649968153284626154111478389914316765783434365458352785868895582488312334931317935669453447478936938533669921165437373741448378477391812779971528975478298688754939216421429251727555596481943322266289527996672856387648674166997731342558986575258793261986817177487197512282162964167151259485744835854547513341322647732662443512251886771887651614177679229984271191292374755915457372775856178539965131319568278252326242615151412772254257847413799811417287481321745372879513766235745347872632946776538173667371228977212143996391617974367923439923774388523845589769341351167311398787797583543434725374343611724379399566197432154146881344528319826434554239373666962546271299717743591225567564655511353255197516515213963862383762258959957474789718564758843367325794589886852413314713698911855183778978722558742329429867239261464773646389484318446574375323674136638452173815176732385468675215264736786242866295648997365412637499692817747937982628518926381939279935993712418938567488289246779458432179335139731952167527521377546376518126276\n"
  }
end
