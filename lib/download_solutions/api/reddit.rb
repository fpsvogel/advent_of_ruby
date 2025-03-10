module DownloadSolutions
  module Api
    class Reddit
      MaxSleepCountReachedError = Class.new(StandardError)
      MultipleMoreChildrensError = Class.new(StandardError)

      # From https://www.reddit.com/r/adventofcode/wiki/archives/solution_megathreads
      MEGATHREAD_IDS = {
        2024 => %w[1h3vp6n 1h4ncyr 1h5frsp 1h689qf 1h71eyz 1h7tovg 1h8l3z5 1h9bdmp 1ha27bo 1hau6hl 1hbm0al 1hcdnk0 1hd4wda 1hdvhvu 1hele8m 1hfboft 1hg38ah 1hguacy 1hhlb8g 1hicdtb 1hj2odw 1hjroap 1hkgj5b 1hl698z 1hlu4ht],
        2023 => %w[1883ibu 188w447 189m3qw 18actmy 18b4b0r 18bwe6t 18cnzbm 18df7px 18e5ytd 18evyu9 18fmrjk 18ge41g 18h940b 18i0xtn 18isayp 18jjpfk 18k9ne5 18l0qtr 18ltr8m 18mmfxb 18nevo3 18o7014 18oy4pc 18pnycy 18qbsxs],
        2022 => %w[z9ezjb zac2v2 zb865p zc0zta zcxid5 zdw0u6 zesk40 zfpnka zgnice zhjfo4 zifqmh zjnruc zkmyh4 zli1rd zmcn64 zn6k1l znykq2 zoqhvy zpihwi zqezkn zrav4h zsct8w zt6xz5 zu28ij zur1an],
        2021 => %w[r66vow r6zd93 r7r0ff r8i1lq r9824c r9z49j rar7ty rbj87a rca6vp rd0s54 rds32p rehj2r rf7onx rfzq6f rgqzt5 rhj2hm ri9kdq rizw2c rjpf7f rkf5ek rl6p8y rlxhmg rmnozs rnejv5 ro2uav],
        2020 => %w[k4e4lm k52psu k5qsrk k6e8sw k71h6r k7ndux k8a31f k8xw8h k9lfwj ka8z8x kaw6oz kbj5me kc4njx kcr1ct kdf85p ke2qp6 keqsfa kfeldk kg1mro kgo01p khaiyk khyjgv kimluc kj96iw kjtg7y],
        2019 => %w[e4axxe e4u0rw e5bz2w e5u5fv e6carb e6tyva e7a4nj e7pkmt e85b6d e8m1z3 e92jm2 e9j0ve e9zgse eafj32 eaurfo ebai4g ebr7dg ec8090 ecogl3 ed5ei2 edll5a ee0rqi eefva8 eewjtt efca4m],
        2018 => %w[a20646 a2aimr a2lesz a2xef8 a3912m a3kr4r a3wmnl a47ubw a4i97s a4skra a53r6i a5eztl a5qd71 a61ojp a6chwa a6mf8a a6wpup a77xq6 a7j9zc a7uk3f a86jgt a8i1cy a8s17l a91ysq a9c61w],
        2017 => %w[7gsrc2 7h0rnm 7h7ufl 7hf5xb 7hngbn 7hvtoq 7i44pg 7icnff 7iksqc 7irzg5 7izym2 7j89tr 7jgyrt 7jpelc 7jxkiw 7k572l 7kc0xw 7kj35s 7kr2ac 7kz6ik 7l78eb 7lf943 7lms6p 7lte5z 7lzo3l],
        2016 => %w[5fur6q 5g1hfm 5g80ck 5gdvve 5gk2yv 5gr0xf 5gy1f2 5h52ro 5hbygy 5hijk5 5hoia9 5hus40 5i1q0h 5i8pzz 5ifn4v 5imh3d 5isvxv 5iyp50 5j4lp1 5jbeqo 5ji29h 5jor9q 5jvbzt 5k1he1 5k6yfu],
        2015 => %w[3uyl7s 3v3w2f 3v8roh 3vdn8a 3viazx 3vmltn 3vr4m4 3vw32y 3w192e 3w6h3m 3wbzyv 3wh73d 3wm0oy 3wqtx2 3wwj84 3x1i26 3x6cyr 3xb3cj 3xflz8 3xjpp2 3xnyoi 3xspyl 3xxdxt 3y1s7f 3y5jco]
      }

      MARKDOWN_PARSER = Redcarpet::Markdown.new(Redcarpet::Render::HTML, fenced_code_blocks: true)

      # @param year [Integer]
      # @param day [Integer]
      def self.megathread_path(year:, day:)
        if year == 2015 && day == 1
          return "/r/programming/comments/#{MEGATHREAD_IDS[2015][0]}/daily_programming_puzzles_at_advent_of_code.json"
        end

        slug = "day_#{day.to_i}_solutions"
        slug = "#{year.to_i}_#{slug}" if year > 2015

        "/r/adventofcode/comments/#{megathread_id(year:, day:)}/#{slug}.json"
      end

      # @param year [Integer]
      # @param day [Integer]
      def self.megathread_id(year:, day:)
        MEGATHREAD_IDS[year.to_i][day - 1]
      end

      private attr_reader :user_agent, :client_id, :client_secret, :username, :password

      def initialize(client_id:, client_secret:, username:, password:)
        @user_agent = "AdventOfRubyScript/#{Arb::VERSION} by fpsvogel"
        @client_id = client_id
        @client_secret = client_secret
        @username = username
        @password = password
      end

      # @param year [Integer]
      # @param day [Integer]
      # @param languages [Array<String>] e.g. ["ruby"]
      def get_comments(year:, day:, languages:)
        thread_id = "t3_#{self.class.megathread_id(year:, day:)}"
        initial_response = get_initial_response(year:, day:)

        # Keep unfetched replies (children) separate so that after filtering
        # (below), the replies to filtered-in comments can then be fetched.
        comments, more_childrens = get_serial_comments(thread_id:, initial_response:)

        filtered_comments = filter_by_language(comments:, languages:)

        filtered_comments.each do |comment|
          add_missing_replies!(comment, comments, more_childrens, thread_id, languages)
        end

        filtered_comments.reject! do |comment|
          comment[:parent_id] != thread_id
        end

        filtered_comments.each do |comment|
          reject_unwanted_replies!(comment)
        end

        filtered_comments.each do |comment|
          clean_body!(comment, languages)
        end

        filtered_comments.each do |comment|
          remove_language_tag!(comment, languages)
        end

        filtered_comments.each do |comment|
          remove_ids!(comment)
        end

        filtered_comments
      end

      private

      # Equivalent to the initial page load of a thread.
      def get_initial_response(year:, day:)
        initial_response = nil

        loop do
          initial_response = connection.get(self.class.megathread_path(year:, day:))

          if initial_response.body.empty?
            puts PASTEL.bright_black("Throttled by Reddit. Sleeping for 60 seconds...")
            sleep 60
          else
            puts "Fetching comments for #{year}##{day.to_s.rjust(2, "0")}..."
            break
          end
        end

        initial_response
      end

      # TODO move into separate class, along with #simplify_comments and #simplify_comment and #simplify_replies
      # Equivalent to repeatedly pressing "View more comments" in a thread's top
      # level (or the "+" below a comment) until reaching the end. "Serial"
      # because this doesn't fetch all replies; many (not all) replies are in
      # "more children" nodes and not yet fetched.
      #
      # @param thread_id [String] e.g. "t3_1h3vp6n".
      # @param parent_id [String] a comment (e.g. "t1_g1a2b3c") or by default the thread_id.
      # @param initial_response [Faraday::Response] if for the top level.
      # @param initial_more_children [Hash] if for a comment.
      def get_serial_comments(thread_id:, parent_id: thread_id, initial_response: nil, initial_more_children: nil)
        more_children = initial_more_children
        comments = []

        loop do
          if initial_response
            comments += simplify_comments(
              JSON.parse(initial_response.body).dig(-1, "data", "children")
            )
          else
            response = nil
            sleep_count = 0
            max_sleep_count = 10
            loop do
              # POST because a GET request would sometimes be too long.
              response = connection.post(
                "/api/morechildren.json",
                "link_id=#{thread_id}" \
                  "&children=#{more_children[:children].join(",")}"
              )

              if response.body.empty?
                if sleep_count < max_sleep_count
                  puts PASTEL.bright_black("Throttled by Reddit. Sleeping for 60 seconds...")
                  sleep_count += 1
                  sleep 60
                else
                  raise MaxSleepCountReachedError
                end
              else
                puts "Continuing to fetch comments..." if sleep_count > 1
                break
              end
            end

            comments += simplify_comments(
              JSON.parse(response.body).dig("jquery", 10, 3, 0)
            )
          end

          initial_response = nil

          more_top_level_childrens, comments = comments.partition { it[:children] && it[:parent_id] == parent_id }

          break unless more_top_level_childrens.any?

          # Only one "more children" node for the top level (or the comment) is
          # expected at any one time. If there are ever more, this algorithm
          # will need to change from a simple (serial) loop to recursion.
          raise MultipleMoreChildrensError if more_top_level_childrens.count > 1

          # Loop again to fetch more if there are more top-level comments.
          more_children = more_top_level_childrens.first
        end

        more_childrens, comments = comments.partition { it[:children] }

        [comments, more_childrens]
      end

      def simplify_comments(raw_comments)
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

      def simplify_comment(raw_comment, raw_more_childrens)
        {
          author: raw_comment["data"]["author"],
          url: "https://www.reddit.com#{raw_comment["data"]["permalink"]}",
          body: raw_comment["data"]["body"],
          id: raw_comment["data"]["name"],
          parent_id: raw_comment["data"]["parent_id"],
          replies: simplify_replies(raw_comment, raw_more_childrens)
        }
      end

      def simplify_replies(raw_comment, raw_more_childrens)
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

      def filter_by_language(comments:, languages:)
        comments.filter { |comment|
          comment_body = comment[:body]&.downcase
          next unless comment_body

          language_specified = comment_body.match?(/\[[[:punct:]]*language:/i)

          if language_specified
            languages.any? { |language|
              comment_body.match?(/\[[[:punct:]]*language:\s*#{language}/i)
            }
          else
            languages.any? { |language|
              # "sh:" because of "<pre class=\"brush:ruby", see:
              # https://github.com/xijo/reverse_markdown/blob/14d53d5f914fd926b49e6492fd7bd95e62ef541a/lib/reverse_markdown/converters/pre.rb#L37
              comment_body.match?(/(?<!```|sh:)#{language}/i)
            }
          end
        }
      end

      def add_missing_replies!(comment, comments, more_childrens, thread_id, languages)
        more_childrens_for_comment = more_childrens.select { it[:parent_id] == comment[:id] }
        more_childrens_for_comment.each do |more_children|
          comments_from_more_children, more_children_from_more_children =
            get_serial_comments(thread_id:, parent_id: comment[:id], initial_more_children: more_children)
          comments += comments_from_more_children
          comments += more_children_from_more_children
        end

        children = comments.filter { it[:parent_id] == comment[:id] }

        comment[:replies] += children

        children.each do |child|
          add_missing_replies!(child, comments, more_childrens, thread_id, languages)
        end

        comment[:replies].uniq!
      end

      def reject_unwanted_replies!(comment)
        comment[:replies].each do |reply|
          reject_unwanted_replies!(reply)
        end

        comment[:replies].reject! do
          (it[:body].strip == "[removed]" && it[:replies].empty?) ||
            %w[AutoModerator daggerdragon backtickbot].include?(it[:author])
        end
      end

      def clean_body!(comment, languages)
        precleaned_body = comment[:body]
          .tr("\u00a0", " ") # Non-breaking space
          # Zero-width space (unintentional); do not remove "\u200b" (intentional, e.g. Unihedron's poems in 2019)
          .gsub("#x200B;", "")
          .gsub("&amp;", "&")
          # Mysterious ampersand, on Reddit an empty paragraph
          .gsub("\n\n&\n\n", "\n\n")
          .delete_suffix("\n\n&")
          .gsub("&lt;", "<")
          .gsub("&gt;", ">")
          .gsub("&#39;", "'")
          # Convert one or two backticks on their own line, to three for a code block.
          .gsub(
            /\\?`(?:\\?`)?(?:#{languages.first})?\n(.+?)\n\\?`(?:\\?`)?(?=\n|\z)/m,
            "\n\n```\n\\1\n```\n"
          )
          .gsub(/    ```.*/, "") # Superfluous backticks (already indented)
          # Add an empty line above code blocks, if missing.
          .gsub(/\n{0,2}```(?:#{languages.first})?/, "\n\n```")

        body_html = MARKDOWN_PARSER.render(precleaned_body)

        body_markdown = body_html
          # https://github.com/xijo/reverse_markdown/blob/14d53d5f914fd926b49e6492fd7bd95e62ef541a/lib/reverse_markdown/converters/pre.rb#L37
          .gsub("<pre>", "<pre class=\"brush:#{languages.first};\">")
          .gsub(/<pre><code class=([^>]+)>/, "<pre class=\\1><code>")
          .then { |cleaned_raw_body|
            ReverseMarkdown.convert(cleaned_raw_body, github_flavored: true)
          }
          .gsub(/ +\n/, "\n") # Strip trailing spaces

        comment[:body] = body_markdown

        comment[:replies].each do |reply|
          clean_body!(reply, languages)
        end
      end

      def remove_language_tag!(comment, languages)
        languages.each do |language|
          comment[:body].sub!(/\[[[:punct:]]*language:\s*#{language}[[:punct:]]*\]/i, "")
        end

        comment[:body].strip!

        comment[:replies].each do |reply|
          remove_language_tag!(reply, languages)
        end
      end

      def remove_ids!(comment)
        comment.delete(:id)
        comment.delete(:parent_id)

        comment[:replies].each do |reply|
          remove_ids!(reply)
        end
      end

      def connection
        @connection ||= Faraday.new(
          url: "https://oauth.reddit.com",
          headers: {
            "User-Agent" => user_agent,
            "Accept" => "application/json"
          }
        ) do |f|
          f.request :authorization, "Bearer", -> { auth_token }
          f.request :retry, {
            max: 5,
            interval: 0.5,
            interval_randomness: 0.5,
            backoff_factor: 2
          }
        end
      end

      def auth_token
        return @auth_token if @auth_token

        connection = Faraday.new(
          url: "https://www.reddit.com",
          headers: {
            "User-Agent" => user_agent
          }
        ) do |f|
          f.request :authorization, :basic, client_id, client_secret
          f.response :json
        end

        response = connection.post(
          "/api/v1/access_token",
          "grant_type=password&username=#{username}&password=#{password}"
        )

        @auth_token = response.body["access_token"]
      end
    end
  end
end
