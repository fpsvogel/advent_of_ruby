require "arb/arb"
require "arb/spec_working_dir"

describe Arb::Cli do
  include Arb::SpecWorkingDir

  describe "::progress" do
    it "shows how many puzzles have been committed in each year where any have been committed" do
      create_working_dir!
      create_fake_solutions!(year: "2016", days: "01".."25")
      create_fake_solutions!(year: "2019", days: "01")
      create_fake_solutions!(year: "2020", days: "10".."20")

      expect(Date).to receive(:today).at_least(:once).and_return(Date.new(2024, 1, 1))

      output = <<~END
        You have completed:

        All:    16.4%   37/225 puzzles

        2016:   100%    25/25
        2019:   4%      1/25
        2020:   44%     11/25
      END

      expect {
        Arb::Cli.progress
      }.to output(
        include_ignoring_colors_and_spacing(output)
      ).to_stdout
    ensure
      remove_working_dir!
    end
  end
end
