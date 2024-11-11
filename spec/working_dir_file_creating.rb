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
end
