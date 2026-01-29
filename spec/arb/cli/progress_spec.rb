require "arb/arb"
require "arb/cli/spec_working_dir"

describe Arb::Cli do
  include Arb::Cli::SpecWorkingDir

  describe "::progress" do
    it "shows how many puzzles have been committed in each year where any have been committed" do
      create_working_dir!
      create_fake_solutions!(year: "2016", days: "01".."25")
      create_fake_solutions!(year: "2019", days: "01")
      create_fake_solutions!(year: "2020", days: "10".."20")

      expected_total = Arb::Util.years_and_max_days.values.flatten.sum
      expected_percent = (37.0 / expected_total * 100).round(1)

      output = <<~END
        You have completed:

        All:    #{expected_percent}%   37/#{expected_total} puzzles

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
