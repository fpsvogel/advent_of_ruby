require "arb/arb"
require "arb/spec_working_dir"

describe Arb::Cli do
  include Arb::SpecWorkingDir

  describe "::commit" do
    let(:year) { "2016" }

    def last_two_commit_messages
      `git log -n 2 --pretty=format:%s`.split("\n")
    end

    def git_status
      `git status -su`
    end

    context "when there are any modified solutions or specs" do
      it "commits the modified ones only, one commit per puzzle" do
        create_working_dir!
        create_fake_solutions!(year: year, days: "01".."02")
        File.write(File.join("src", year, "03.rb"), "a new fake solution")
        File.write(File.join("src", year, "01.rb"), "a modified fake solution")
        File.write(File.join("spec", year, "01_spec.rb"), "a modified fake spec")
        File.write(File.join("src", year, "02.rb"), "a modified fake solution")

        outputs = [
          "Puzzle #{year}#01 (modified) committed",
          "Puzzle #{year}#02 (modified) committed",
        ]
        commit_messages = [
          "Improve #{year}#01",
          "Improve #{year}#02",
        ]

        expect {
          Arb::Cli.commit
        }.to output(
          include(outputs[0])
          .and include(outputs[1])
        ).to_stdout

        expect(last_two_commit_messages).to eq commit_messages.reverse
        expect(git_status).to eq "?? src/#{year}/03.rb\n"
      ensure
        remove_working_dir!
      end
    end

    context "when there are only new solutions or specs" do
      it "commits the new ones only, one commit per puzzle" do
        create_working_dir!
        Dir.mkdir(File.join("src", year))
        Dir.mkdir(File.join("spec", year))
        File.write(File.join("src", year, "01.rb"), "a new solution")
        File.write(File.join("spec", year, "01_spec.rb"), "a new spec")
        File.write(File.join("src", year, "02.rb"), "a new solution")

        outputs = [
          "Puzzle #{year}#01 committed",
          "Puzzle #{year}#02 committed",
        ]
        commit_messages = [
          "Solve #{year}#01",
          "Solve #{year}#02",
        ]

        expect {
          Arb::Cli.commit
        }.to output(
          include(outputs[0])
          .and include(outputs[1])
        ).to_stdout

        expect(last_two_commit_messages).to eq commit_messages.reverse
        expect(git_status).to eq ""
      ensure
        remove_working_dir!
      end
    end
  end
end
