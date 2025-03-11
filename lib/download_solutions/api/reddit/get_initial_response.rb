module DownloadSolutions
  module Api
    class Reddit
      class GetInitialResponse
        # Equivalent to the initial page load of a Reddit thread, which loads
        # some comments, but (if the thread has many comments) not all of them.
        #
        # @param params [Reddit::Params]
        # @return [Faraday::Response]
        def self.call(params:)
          initial_response = nil

          loop do
            initial_response = params.connection.get(params.megathread_path)

            if initial_response.body.empty?
              puts PASTEL.bright_black("Throttled by Reddit. Sleeping for 60 seconds...")
              sleep 60
            else
              puts "Fetching comments for #{params.year}##{params.day.to_s.rjust(2, "0")}..."
              break
            end
          end

          initial_response
        end
      end
    end
  end
end
