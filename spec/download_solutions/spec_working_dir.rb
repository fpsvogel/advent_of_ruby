module DownloadSolutions
  module SpecWorkingDir
    # @param service [Symbol] :github or :reddit
    def create_working_dir!(service:)
      @original_dir = Dir.pwd
      # Not nested in @original_dir (gem root) because in Arb::SpecWorkingDir
      # it needs to be a separate Git repo.
      @working_dir = File.join(Dir.home, "arb_temp")

      if Dir.exist?(@working_dir)
        `rm -rf #{@working_dir}`
      end

      Dir.mkdir(@working_dir)
      Dir.chdir(@working_dir)

      if service == :github
        dotenv = <<~END.chomp
          GITHUB_TOKEN=stubbed_github_token
        END
      elsif service == :reddit
        dotenv = <<~END.chomp
          REDDIT_CLIENT_ID=stubbed_reddit_client_id
          REDDIT_CLIENT_SECRET=stubbed_reddit_client_secret
          REDDIT_USERNAME=fpsvogel
          REDDIT_PASSWORD=stubbed_reddit_password
        END
      end
      File.write(".env", dotenv)

      Dir.mkdir("data")
      Dir.mkdir(File.join("data", "solutions"))
      Dir.mkdir(File.join("data", "solutions", service.to_s))
    end

    def remove_working_dir!
      Dir.chdir(@original_dir)
      `rm -rf #{@working_dir}`
    end
  end
end
