module DownloadSolutions
  module Api
    class Reddit
      class GetSerialComments
        MAX_SLEEP_COUNT = 10

        # Equivalent to repeatedly pressing "View more comments" in a thread's top
        # level (or the "+" below a comment) until reaching the end. "Serial"
        # because this doesn't fetch all replies; many (not all) replies are in
        # "more children" nodes and not yet fetched.
        #
        # @param params [Reddit::Params]
        # @param parent_id [String] the ID of the parent, by default the thread.
        # @return [Array(Array<Hash>, Array<Hash>)] comments and "more children" nodes.
        #
        # @raise [MaxSleepCountReachedError] if Reddit seemingly throttled for an
        #   unusually long time, "seemingly" because the only sign is an empty
        #   JSON response body after loading additional comments.
        # @raise [MultipleMoreChildrensError] if there are multiple "more children"
        #   nodes for the thread or a comment; only one at a time is expected.
        #   If there are ever more, this algorithm will need to change from a
        #   serial loop to recursion.
        def self.call(params:, parent_id: params.thread_id)
          comments = initial_comments_or_replies(params, parent_id) || (return [[], []])

          loop do
            more_top_level_childrens, comments = comments.partition {
              it[:children] && it[:parent_id] == parent_id
            }
            break unless more_top_level_childrens.any?
            raise Reddit::MultipleMoreChildrensError if more_top_level_childrens.count > 1

            # Loop again to fetch more if there are more top-level comments.
            comments += fetch_more_children(params, more_top_level_childrens.first, parent_id)
          end

          more_childrens, comments = comments.partition { it[:children] }

          [comments, more_childrens]
        end

        private_class_method def self.initial_comments_or_replies(params, parent_id)
          if parent_id == params.thread_id
            parse_initial_response(params)
          else
            more_childrens = params.more_childrens.select {
              it[:parent_id] == parent_id
            }
            raise Reddit::MultipleMoreChildrensError if more_childrens.count > 1

            if more_childrens.empty?
              # signal to return empty arrays for comments and more_childrens
              return nil
            end

            fetch_more_children(params, more_childrens.first, parent_id)
          end
        end

        private_class_method def self.parse_initial_response(params)
          simplify_comments(
            JSON.parse(params.initial_response.body).dig(-1, "data", "children")
          )
        end

        private_class_method def self.fetch_more_children(params, more_children, parent_id)
          response = nil
          sleep_count = 0
          loop do
            # POST because a GET request would sometimes be too long.
            response = params.connection.post(
              "/api/morechildren.json",
              "link_id=#{params.thread_id}" \
                "&children=#{more_children[:children].join(",")}"
            )

            if response.body.empty?
              if sleep_count < MAX_SLEEP_COUNT
                puts PASTEL.bright_black("Throttled by Reddit. Sleeping for 60 seconds...")
                sleep_count += 1
                sleep 60
              else
                raise Reddit::MaxSleepCountReachedError
              end
            else
              puts "Continuing to fetch comments..." if sleep_count > 1
              break
            end
          end

          simplify_comments(
            JSON.parse(response.body).dig("jquery", 10, 3, 0)
          )
        end

        private_class_method def self.simplify_comments(raw_comments)
          raw_more_childrens, raw_comments = raw_comments.partition { it["kind"] == "more" }

          comments = raw_comments.map { |raw_comment|
            simplify_comment(raw_comment, raw_more_childrens)
          }

          more_childrens = raw_more_childrens.filter_map {
            if it["data"]["children"].any?
              {
                children: it["data"]["children"],
                parent_id: it["data"]["parent_id"]
              }
            end
          }

          comments + more_childrens
        end

        private_class_method def self.simplify_comment(raw_comment, raw_more_childrens)
          {
            author: raw_comment["data"]["author"],
            url: "https://www.reddit.com#{raw_comment["data"]["permalink"]}",
            body: raw_comment["data"]["body"],
            id: raw_comment["data"]["name"],
            parent_id: raw_comment["data"]["parent_id"],
            replies: simplify_replies(raw_comment, raw_more_childrens)
          }
        end

        private_class_method def self.simplify_replies(raw_comment, raw_more_childrens)
          return [] if raw_comment["data"]["replies"].nil? || raw_comment["data"]["replies"].empty?

          raw_comment.dig("data", "replies", "data", "children").filter_map { |child|
            if child["kind"] == "more"
              # Move "more children" nodes (listing additional replies that are
              # not yet fetched) out to an array that is appended onto the
              # upper-level comments (see #simplify_comments), so that they can
              # all be dealt with together by #add_missing_replies!
              raw_more_childrens << child
              next nil
            end

            simplify_comment(child, raw_more_childrens)
          }
        end
      end
    end
  end
end
