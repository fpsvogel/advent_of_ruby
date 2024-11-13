require "arb/arb"
require "working_dir_file_creating"

describe Arb::Cli do
  include WorkingDirFileCreating

  describe "::run" do
    let(:year) { "2017" }
    let(:day) { "01" }
    let(:input_2017_01) {
      "61697637962276641366442297247367117738114719863473648131982449728688116728695866572989524473392982963976411147683588415878214189996163533584547175794158118148724298832798898333399786561459152644144669959887341481968319172987357989785791366732849932788343772112176614723858474959919713855398876956427631354172668133549845585632211935573662181331613137869866693259374322169811683635325321597242889358147123358117774914653787371368574784376721652181792371635288376729784967526824915192526744935187989571347746222113625577963476141923187534658445615596987614385911513939292257263723518774888174635963254624769684533531443745729344341973746469326838186248448483587477563285867499956446218775232374383433921835993136463383628861115573142854358943291148766299653633195582135934544964657663198387794442443531964615169655243652696782443394639169687847463721585527947839992182415393199964893658322757634675274422993237955354185194868638454891442893935694454324235968155913963282642649968153284626154111478389914316765783434365458352785868895582488312334931317935669453447478936938533669921165437373741448378477391812779971528975478298688754939216421429251727555596481943322266289527996672856387648674166997731342558986575258793261986817177487197512282162964167151259485744835854547513341322647732662443512251886771887651614177679229984271191292374755915457372775856178539965131319568278252326242615151412772254257847413799811417287481321745372879513766235745347872632946776538173667371228977212143996391617974367923439923774388523845589769341351167311398787797583543434725374343611724379399566197432154146881344528319826434554239373666962546271299717743591225567564655511353255197516515213963862383762258959957474789718564758843367325794589886852413314713698911855183778978722558742329429867239261464773646389484318446574375323674136638452173815176732385468675215264736786242866295648997365412637499692817747937982628518926381939279935993712418938567488289246779458432179335139731952167527521377546376518126276\n"
    }

    # Chains a matcher on the given collection, using #and.
    def match_all(matcher_name, collection)
      if collection.empty?
        satisfy { true }
      else
        collection.reduce(send(matcher_name, collection.shift)) { |matcher, el|
          matcher.and(send(matcher_name, el))
        }
      end
    end

    def run_with(options: {}, outputs:, not_outputs: [])
      expect {
        Arb::Cli.run(year: nil, day: nil, options:)
      }.to output(
        match_all(:include_ignoring_colors_and_spacing, outputs)
        .and(match_all(:not_include_ignoring_colors_and_spacing, not_outputs))
      ).to_stdout_from_any_process
    end

    context "when a puzzle has just been bootstrapped" do
      it "runs Part One specs" do
        create_working_dir!
        create_puzzle!

        outputs = [
          <<~OUT
            F*

            Pending: (Failures listed here are expected and do not affect your suite's status)

              1) Year#{year}::Day#{day} solves Part Two
                 # Temporarily skipped with xit
                 # ./spec/#{year}/#{day}_spec.rb:14

            Failures:

              1) Year#{year}::Day#{day} solves Part One
                 Failure/Error: expect(subject.part_1(input)).to eq(:todo)

                   expected: :todo
                        got: nil

                   (compared using ==)
                 # ./spec/#{year}/#{day}_spec.rb:11:in `block (2 levels) in <top (required)>'
          OUT
        ]

        run_with(outputs:)
      ensure
        remove_working_dir!
      end
    end

    context "when Part One has been solved" do
      it "runs Part One and prompts to submit it", vcr: "run_2017_01_1" do
        create_working_dir!
        solution, spec = part_one_solution, part_one_specs
        create_puzzle!(solution:, spec:)

        outputs = [
          <<~OUT,
            Specs passed!

            Result for 2017#01.1:
            1182
          OUT
          "Submit solution? (Y/n)",
          "That's the right answer! You are one gold star closer to debugging the printer.",
          "Downloaded instructions for Part Two.",
        ]

        expect(STDIN).to receive(:gets).once.and_return("\n") # default "Y" to submit
        instructions_file_path = File.join("instructions", year, "#{day}.md")
        expect(described_class).to receive(:`).with("code #{instructions_file_path}")

        run_with(outputs:)

        expect_instructions_file_to_have_been_redownloaded(year:, day:)
        expect_part_two_spec_to_have_been_unskipped(year:, day:)
      ensure
        remove_working_dir!
      end
    end

    context "when Part Two has been solved" do
      it "runs Part Two and prompts to submit it", vcr: "run_2017_01_2" do
        create_working_dir!
        previously_submitted_answers = [1182]
        solution, spec = part_two_solution, part_two_specs
        create_puzzle!(solution:, spec:, previously_submitted_answers:)

        outputs = [
          <<~OUT,
            Specs passed!

            Result for 2017#01.2:
            1152
          OUT
          "Submit solution? (Y/n)",
          "That's the right answer! You are one gold star closer to debugging the printer.",
        ]

        expect(STDIN).to receive(:gets).once.and_return("\n") # default "Y" to submit

        run_with(outputs:)
      ensure
        remove_working_dir!
      end
    end

    context "when both parts have been solved" do
      it "runs both parts" do
        create_working_dir!
        previously_submitted_answers = [1182, 1152]
        solution, spec = part_two_solution, part_two_specs
        create_puzzle!(solution:, spec:, previously_submitted_answers:)

        outputs = [
          <<~OUT,
            Specs passed!

            Result for 2017#01.1:
            ✅ 1182
          OUT
          <<~OUT,
            Result for 2017#01.2:
            ✅ 1152
          OUT
          "You've already submitted the answers to both parts.",
        ]

        run_with(outputs:)
      ensure
        remove_working_dir!
      end
    end

    context "when both parts have been committed" do
      it "runs both parts" do
        create_working_dir!
        previously_submitted_answers = [1182, 1152]
        solution, spec = part_two_solution, part_two_specs
        create_puzzle!(solution:, spec:, previously_submitted_answers:)

        `git add -A`
        `git commit -m "Solve #{year}##{day}"`

        outputs = [
          <<~OUT,
            Specs passed!

            Result for 2017#01.1:
            ✅ 1182
          OUT
          <<~OUT,
            Result for 2017#01.2:
            ✅ 1152
          OUT
          "You've already submitted the answers to both parts.",
        ]

        run_with(outputs:)
      ensure
        remove_working_dir!
      end
    end

    context "with --spec flag" do
      it "runs only specs" do
        create_working_dir!
        previously_submitted_answers = [1182, 1152]
        solution, spec = part_two_solution, part_two_specs
        create_puzzle!(solution:, spec:, previously_submitted_answers:)

        options = {spec: true}
        outputs = ["2 examples, 0 failures"]
        not_outputs = [
          <<~OUT,
            Result for 2017#01.1:
            ✅ 1182
          OUT
          <<~OUT,
            Result for 2017#01.2:
            ✅ 1152
          OUT
        ]

        run_with(options:, outputs:, not_outputs:)
      ensure
        remove_working_dir!
      end
    end

    context "with --one flag" do
      it "runs only Part One" do
        create_working_dir!
        previously_submitted_answers = [1182, 1152]
        solution, spec = part_two_solution, part_two_specs
        create_puzzle!(solution:, spec:, previously_submitted_answers:)

        options = {one: true}
        outputs = [
          <<~OUT,
            Result for 2017#01.1:
            ✅ 1182
          OUT
          "You've already submitted the answers to both parts.",
        ]
        not_outputs = [
          "Specs passed!",
          <<~OUT,
            Result for 2017#01.2:
            ✅ 1152
          OUT
        ]

        run_with(options:, outputs:, not_outputs:)
      ensure
        remove_working_dir!
      end
    end

    context "with --two flag" do
      it "runs only Part Two" do
        create_working_dir!
        previously_submitted_answers = [1182, 1152]
        solution, spec = part_two_solution, part_two_specs
        create_puzzle!(solution:, spec:, previously_submitted_answers:)

        options = {two: true}
        outputs = [
          <<~OUT,
            Result for 2017#01.2:
            ✅ 1152
          OUT
          "You've already submitted the answers to both parts.",
        ]
        not_outputs = [
          "Specs passed!",
          <<~OUT,
            Result for 2017#01.1:
            ✅ 1182
          OUT
        ]

        run_with(options:, outputs:, not_outputs:)
      ensure
        remove_working_dir!
      end
    end

    context "with --variant flag" do
      it "runs a variant, if it exists" do
        create_working_dir!
        previously_submitted_answers = [1182, 1152]
        solution, spec = variant_solution, part_two_specs
        create_puzzle!(solution:, spec:, previously_submitted_answers:)

        options = {variant: "golf"}
        outputs = [
          <<~OUT,
            Specs passed!

            Result for 2017#01.1 (variant `golf`):
            ✅ 1182
          OUT
          <<~OUT,
            Result for 2017#01.2:
            ✅ 1152
          OUT
          "You've already submitted the answers to both parts.",
        ]

        run_with(options:, outputs:)
      ensure
        remove_working_dir!
      end
    end
  end

  # File expectations

  def expect_instructions_file_to_have_been_redownloaded(year:, day:)
    instructions = File.read(File.join("instructions", year, "#{day}.md"))
    expect(instructions).to include("## --- Part Two ---")
  end

  def expect_part_two_spec_to_have_been_unskipped(year:, day:)
    spec_file = File.read(File.join("spec", year, "#{day}_spec.rb"))
    expect(spec_file).to include(/^\s*it "solves Part Two" do/)
  end

  # File creation/editing

  def create_puzzle!(solution: nil, spec: nil, previously_submitted_answers: [])
    input = input_2017_01

    instructions = "## Day 1\n\nSome instructions.\n"
    previously_submitted_answers.each do |answer|
      instructions << "\nYour puzzle answer was `#{answer}`.\n"
    end
    Dir.mkdir("instructions")
    Dir.mkdir(File.join("instructions", year))
    File.write(File.join("instructions", year, "#{day}.md"), instructions)

    Dir.mkdir("input")
    Dir.mkdir(File.join("input", year))
    File.write(File.join("input", year, "#{day}.txt"), input)

    Dir.mkdir(File.join("src", year))
    File.write(File.join("src", year, "#{day}.rb"), solution || Arb::Files::Source.source(year, day))
    load "#{Dir.pwd}/src/#{year}/#{day}.rb"

    Dir.mkdir(File.join("spec", year))
    File.write(File.join("spec", year, "#{day}_spec.rb"), spec || Arb::Files::Spec.source(year, day))
  end

  def part_one_solution
    <<~SRC
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
  end

  def part_one_specs
    <<~SPEC
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
  end

  def part_two_solution
    <<~SRC
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
  end

  def part_two_specs
    <<~SPEC
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
  end

  def variant_solution
    <<~SRC
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

          def part_1_golf(input_file)
            input_file.read.chomp.chars.map(&:to_i).tap { _1 << _1.first }.each_cons(2).sum { _1 == _2 ? _1 : 0 }
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
  end
end
