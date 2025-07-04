module Arb
  module SpecWorkingDir
    def working_dir_files
      @working_dir_files ||= {
        ".env" => <<~END.chomp,
          EDITOR_COMMAND=code
          AOC_COOKIE=stubbed_session_cookie
        END
        **Arb::Cli::WorkingDirectory::FILES,
        ".rspec" => "--require spec_helper\n"
      }
    end

    def create_working_dir!(create_files: true)
      @original_dir = Dir.pwd
      # Not nested in @original_dir (gem root) because it needs to be a separate Git repo.
      @working_dir = File.join(Dir.home, "arb_temp")

      if Dir.exist?(@working_dir)
        `rm -rf #{@working_dir}`
      end

      Dir.mkdir(@working_dir)
      Dir.chdir(@working_dir)

      if create_files
        Dir.mkdir("src")
        Dir.mkdir("spec")

        working_dir_files.each do |filename, contents|
          File.write(filename, contents)
        end

        `git init`
        `git add -A`
        `git commit -m "Initial commit"`
      end
    end

    def remove_working_dir!
      Dir.chdir(@original_dir)
      `rm -rf #{@working_dir}`
    end

    # @param year [String]
    # @param days [Object] anything that can be #Array coerced into an array of
    #   strings, e.g. an Integer or a Range.
    def create_fake_solutions!(year:, days:, git_commits: false)
      Dir.mkdir(File.join("src", year)) unless Dir.exist?(File.join("src", year))
      Dir.mkdir(File.join("spec", year)) unless Dir.exist?(File.join("spec", year))

      days = Array(days).map(&:to_s)
      days.each do |day|
        day = day.rjust(2, "0") if day.length == 1
        File.write(File.join("src", year, "#{day}.rb"), "a fake solution")
        File.write(File.join("spec", year, "#{day}_spec.rb"), "a fake spec")

        `git add -A`
        `git commit -m "Solve #{year}##{day}"`
      end
    end
  end
end
