module WorkingDirFileCreating
  def working_dir_files
    @working_dir_files ||= {
      ".env" => <<~FILE.chomp,
        EDITOR_COMMAND=code
        AOC_COOKIE=stubbed_session_cookie
      FILE
      **Arb::Cli::WorkingDirectory::FILES,
      ".rspec" => "--require spec_helper\n",
    }
  end

  def create_working_dir!(create_files: true)
    @original_dir = Dir.pwd
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
      padded_day = day.rjust(2, "0")
      File.write(File.join("src", year, "#{padded_day}.rb"), "a fake solution")
      File.write(File.join("spec", year, "#{padded_day}_spec.rb"), "a fake spec")

      `git add -A`
      `git commit -m "Solve #{year}##{padded_day}"`
    end
  end
end
