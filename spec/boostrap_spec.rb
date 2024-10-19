require "arb/arb"

describe Arb::Cli do
  describe "::bootstrap" do
    context "when all working directory files already exist" do
      it "downloads the next puzzle", vcr: "bootstrap_2020_01" do
        tmp, original_pwd = change_to_tmp_dir
        setup_tmp_dir(tmp)
        year, day = "2020", "1"

        expect_files_will_be_opened_in_editor(year:, day:)

        expect {
          Arb::Cli.bootstrap(year:, day:)

          expect_files_to_have_correct_contents(year:, day:)
        }.to output(match("🤘 Bootstrapped 2020#1")).to_stdout
        .and not_output(match("✅ Initial files created and committed to a new Git repository.")).to_stdout
      ensure
        remove_tmp_dir(tmp, original_pwd)
      end

      def expect_files_will_be_opened_in_editor(year:, day:)
        puzzle_files(year:, day:).values.each do |path|
          expect(described_class).to receive(:`).with("code #{path}").ordered
        end
      end

      def expect_files_to_have_correct_contents(year:, day:)
        contents = puzzle_files(year:, day:).transform_values { File.read _1 }

        expect(contents.values).to all not_be_empty
        expect(contents[:instructions]).to start_with("## --- Day #{day}: ")
        expect(contents[:instructions]).to end_with("https://adventofcode.com/#{year}/day/#{day}\n")
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

      def change_to_tmp_dir
        original_pwd = Dir.pwd
        tmp = File.join(Dir.pwd, "spec", "tmp")
        if Dir.exist?(tmp)
          remove_tmp_dir(tmp, original_pwd)
        end

        Dir.mkdir(tmp)
        Dir.chdir(tmp)
        [tmp, original_pwd]
      end

      def remove_tmp_dir(tmp, original_pwd)
        Dir.chdir(original_pwd)
        `rm -rf #{tmp}`
      end

      def setup_tmp_dir(tmp)
        dotenv = <<~FILE
          EDITOR_COMMAND=code
          AOC_COOKIE=stubbed_session_cookie
        FILE
        gitignore, ruby_version, gemfile, spec_helper_addition =
          Arb::Cli::WorkingDirectory::FILES.values

        Dir.mkdir("src")
        Dir.mkdir("spec")
        File.write( ".env", dotenv)
        File.write( ".gitignore", gitignore)
        File.write( ".ruby-version", ruby_version)
        File.write( "Gemfile", gemfile)
        # TODO: in the future spec that checks `bootstrap` file creation:
        # when checking the created file's contents, just check for the addition.
        File.write(File.join("spec", "spec_helper.rb"), spec_helper_addition)
        File.write(".rspec", "--require spec_helper\n")

        `git init`
        `git add -A`
        `git commit -m "Initial commit"`
      end
    end
  end
end
