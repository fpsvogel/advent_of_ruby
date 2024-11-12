require "arb/arb"
require "working_dir_file_creating"

describe Arb::Cli do
  include WorkingDirFileCreating

  describe "::progress" do
    it "shows how many puzzles have been committed in each year where any have been committed" do
      create_working_dir!
      create_fake_solutions!(year: "2016", days: "01".."25")
      create_fake_solutions!(year: "2019", days: "01")
      create_fake_solutions!(year: "2020", days: "10".."20")

      output = <<~OUT
        You have completed:

        All:    16.4%   37/225 puzzles

        2016:   100%    25/25
        2019:   4%      1/25
        2020:   44%     11/25
      OUT

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
