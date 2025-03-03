module Arb
  module Api
    class Reddit
      # TODO WIP
      # https://www.reddit.com/r/redditdev/comments/12f885c/getting_all_the_comments_in_a_post/
      # https://gist.github.com/davestevens/4257bbfc82b1e59eeec7085e66314215#get-all-comments
      # https://www.reddit.com/r/redditdev/comments/v7sw57/will_i_get_all_the_comments_of_a_post_through/
      # https://www.reddit.com/dev/api/oauth#GET_comments_%7Barticle%7D
      # https://www.reddit.com/r/adventofcode/comments/1h3vp6n/2024_day_1_solutions/

      # From https://www.reddit.com/r/adventofcode/wiki/archives/solution_megathreads
      MEGATHREADS = {
        2024 => %w[1h3vp6n 1h4ncyr 1h5frsp 1h689qf 1h71eyz 1h7tovg 1h8l3z5 1h9bdmp 1ha27bo 1hau6hl 1hbm0al 1hcdnk0 1hd4wda 1hdvhvu 1hele8m 1hfboft 1hg38ah 1hguacy 1hhlb8g 1hicdtb 1hj2odw 1hjroap 1hkgj5b 1hl698z 1hlu4ht],
        2023 => %w[1883ibu 188w447 189m3qw 18actmy 18b4b0r 18bwe6t 18cnzbm 18df7px 18e5ytd 18evyu9 18fmrjk 18ge41g 18h940b 18i0xtn 18isayp 18jjpfk 18k9ne5 18l0qtr 18ltr8m 18mmfxb 18nevo3 18o7014 18oy4pc 18pnycy 18qbsxs],
        2022 => %w[z9ezjb zac2v2 zb865p zc0zta zcxid5 zdw0u6 zesk40 zfpnka zgnice zhjfo4 zifqmh zjnruc zkmyh4 zli1rd zmcn64 zn6k1l znykq2 zoqhvy zpihwi zqezkn zrav4h zsct8w zt6xz5 zu28ij zur1an],
        2021 => %w[r66vow r6zd93 r7r0ff r8i1lq r9824c r9z49j rar7ty rbj87a rca6vp rd0s54 rds32p rehj2r rf7onx rfzq6f rgqzt5 rhj2hm ri9kdq rizw2c rjpf7f rkf5ek rl6p8y rlxhmg rmnozs rnejv5 ro2uav],
        2020 => %w[k4e4lm k52psu k5qsrk k6e8sw k71h6r k7ndux k8a31f k8xw8h k9lfwj ka8z8x kaw6oz kbj5me kc4njx kcr1ct kdf85p ke2qp6 keqsfa kfeldk kg1mro kgo01p khaiyk khyjgv kimluc kj96iw kjtg7y],
        2019 => %w[e4axxe e4u0rw e5bz2w e5u5fv e6carb e6tyva e7a4nj e7pkmt e85b6d e8m1z3 e92jm2 e9j0ve e9zgse eafj32 eaurfo ebai4g ebr7dg ec8090 ecogl3 ed5ei2 edll5a ee0rqi eefva8 eewjtt efca4m],
        2018 => %w[a20646 a2aimr a2lesz a2xef8 a3912m a3kr4r a3wmnl a47ubw a4i97s a4skra a53r6i a5eztl a5qd71 a61ojp a6chwa a6mf8a a6wpup a77xq6 a7j9zc a7uk3f a86jgt a8i1cy a8s17l a91ysq a9c61w],
        2017 => %w[7gsrc2 7h0rnm 7h7ufl 7hf5xb 7hngbn 7hvtoq 7i44pg 7icnff 7iksqc 7irzg5 7izym2 7j89tr 7jgyrt 7jpelc 7jxkiw 7k572l 7kc0xw 7kj35s 7kr2ac 7kz6ik 7l78eb 7lf943 7lms6p 7lte5z 7lzo3l],
        2016 => %w[5fur6q 5g1hfm 5g80ck 5gdvve 5gk2yv 5gr0xf 5gy1f2 5h52ro 5hbygy 5hijk5 5hoia9 5hus40 5i1q0h 5i8pzz 5ifn4v 5imh3d 5isvxv 5iyp50 5j4lp1 5jbeqo 5ji29h 5jor9q 5jvbzt 5k1he1 5k6yfu],
        2015 => %w[3uyl7s 3v3w2f 3v8roh 3vdn8a 3viazx 3vmltn 3vr4m4 3vw32y 3w192e 3w6h3m 3wbzyv 3wh73d 3wm0oy 3wqtx2 3wwj84 3x1i26 3x6cyr 3xb3cj 3xflz8 3xjpp2 3xnyoi 3xspyl 3xxdxt 3y1s7f 3y5jco],
      }

      def self.megathread_path(year:, day:)
        if year.to_i == 2015 && day.to_i == 1
          return "/r/programming/comments/#{MEGATHREADS[2015][0]}/daily_programming_puzzles_at_advent_of_code/"
        end

        slug = "day_#{day.to_i}_solutions"
        slug = "#{year.to_i}_#{slug}" if year.to_i > 2015

        "/r/adventofcode/comments/#{megathread_id(year:, day:)}/#{slug}.json"
      end

      def self.megathread_id(year:, day:)
        MEGATHREADS[year.to_i][day.to_i - 1]
      end

      private attr_reader :user_agent, :client_id, :client_secret, :username, :password

      def initialize(client_id:, client_secret:, username:, password:)
        @user_agent = "AdventOfRubyScript/#{Arb::VERSION} by fpsvogel"
        @client_id = client_id
        @client_secret = client_secret
        @username = username
        @password = password
      end

      def get_comments(year:, day:, language_names:)
        debugger if day > 25
        thread_id = "t3_#{self.class.megathread_id(year:, day:)}"
        initial_response = nil
        loop do
          initial_response = connection.get(self.class.megathread_path(year:, day:))

          if initial_response.body.empty?
            puts "Throttled by Reddit. Sleeping for 30 seconds..."
            sleep 30
          else
            puts "Fetching comments for #{year}##{day.to_s.rjust(2, "0")}..."
            break
          end
        end

        comments = get_comments_for(thread_id:, initial_response:)

        # Lists of unfetched replies (children) are kept separate so that those
        # that are replies to a comment that will have been kept in filtering
        # (below) they can then be fetched.
        more_childrens, comments = comments.partition { it[:children] }

        # Filter comments by language.
        filtered_comments = comments.filter { |comment|
          comment_body = comment[:body]&.downcase
          next unless comment_body

          language_specified = comment_body.match?(/\[[[:punct:]]*language:/i)

          if language_specified
            language_names.any? { |language|
              comment_body.match?(/\[[[:punct:]]*language:\s*#{language}/i)
            }
          else
            language_names.any? { |language| comment_body.match?(/(?<!```)#{language}/i) }
          end
        }

        filtered_comments.each do |comment|
          add_missing_replies!(comment, comments, more_childrens, thread_id)
        end

        filtered_comments.each do |comment|
          remove_language_tag!(comment, language_names)
        end

        filtered_comments.reject! do |comment|
          comment[:parent_id] != thread_id
        end

        filtered_comments.each do |comment|
          remove_ids!(comment)
        end

        filtered_comments
      end

      private

      def connection
        @connection ||= Faraday.new(
          url: "https://oauth.reddit.com",
          headers: {
            "User-Agent" => user_agent,
            "Accept" => "application/json",
          }
        ) do |f|
          f.request :authorization, "Bearer", -> { auth_token }
        end
      end

      def auth_token
        return @auth_token if @auth_token

        connection = Faraday.new(
          url: "https://www.reddit.com",
          headers: {
            "User-Agent" => user_agent,
          }
        ) do |f|
          f.request :authorization, :basic, client_id, client_secret
          f.response :json
        end

        response = connection.post(
          "/api/v1/access_token",
          "grant_type=password&username=#{username}&password=#{password}",
        )

        @auth_token = response.body["access_token"]
      end

      def get_comments_for(thread_id:, parent_id: thread_id, initial_response: nil, more_children: nil)
        comments = []

        loop do
          if initial_response
            comments += simplify_comments(
              JSON.parse(initial_response.body).dig(-1, "data", "children")
            )
          else
            response = connection.post(
              "/api/morechildren.json",
              "link_id=#{thread_id}" \
                "&children=#{more_children[:children].join(",")}",
            )

            # Occasionally there is an empty set of more children, e.g. below
            # zaniwoop near the bottom of the 2024 day 1 solutions megathread.
            return comments if response.body.empty?

            comments += simplify_comments(
              JSON.parse(response.body).dig("jquery", 10, 3, 0)
            )
          end

          initial_response = nil

          more_top_level_childrens, comments = comments.partition { it[:children] && it[:parent_id] == parent_id }

          break unless more_top_level_childrens.any?

          if more_top_level_childrens.count > 1
            debugger
          end

          # Loop again to fetch more if there are more top-level comments.
          more_children = more_top_level_childrens.first
        end

        comments
      end

      def simplify_comments(raw_comments)
        more_childrens_from_replies = []

        comments = raw_comments.filter_map { |raw_comment|
          # If it is a list of more children.
          if raw_comment["kind"] == "more"
            more_children = {
              children: raw_comment["data"]["children"],
              parent_id: raw_comment["data"]["parent_id"],
            }

            if more_children[:children].any?
              next more_children
            else
              next nil
            end
          end

          {
            author: raw_comment["data"]["author"],
            url: "https://www.reddit.com#{raw_comment["data"]["permalink"]}",
            body: body_markdown(raw_comment["data"]["body_html"]),
            id: raw_comment["data"]["name"],
            parent_id: raw_comment["data"]["parent_id"],
            replies: simplify_replies(raw_comment, more_childrens_from_replies),
          }
        }

        comments + more_childrens_from_replies
      end

      # Extracts replies that came along with the comment. (Other replies are
      # represented in `more_children` and have yet to be fetched.)
      def simplify_replies(raw_comment, more_childrens_from_replies)
        debugger if raw_comment["data"]["replies"].nil?
        return [] if raw_comment["data"]["replies"].empty?

        raw_comment["data"]["replies"]["data"]["children"].filter_map { |child|
          next nil if %w[AutoModerator daggerdragon].include?(child["data"]["author"])
          next nil if child["data"]["body"] == "[removed]"

          if child["kind"] == "more"
            # Move "more children" lists out to an array that is appended
            # onto the top-level comments (below), because that's where
            # other "more children" lists may be, and that way they can all
            # be dealt with together by #add_missing_replies!
            more_children = {
              children: child["data"]["children"],
              parent_id: child["data"]["parent_id"],
            }

            more_childrens_from_replies << more_children if more_children[:children].any?

            next nil
          end

          {
            author: child["data"]["author"],
            url: "https://www.reddit.com#{child["data"]["permalink"]}",
            body: body_markdown(child["data"]["body_html"]),
            id: child["data"]["name"],
            parent_id: child["data"]["parent_id"],
            replies: simplify_replies(child, more_childrens_from_replies),
          }
        }
      end

      def body_markdown(body_html)
        body_html
          .gsub("\u00a0", " ")
          .gsub("&amp;", "&")
          .gsub("&lt;", "<")
          .gsub("&gt;", ">")
          .sub(/\A<div class="md">/, "")
          .sub(/<\/div>\z/, "")
          # https://github.com/xijo/reverse_markdown/blob/14d53d5f914fd926b49e6492fd7bd95e62ef541a/lib/reverse_markdown/converters/pre.rb#L37
          .gsub("<pre>", "<pre class=\"brush:ruby;\">")
          .gsub(/ +\n/, "\n")
          .then { |cleaned_body_html|
            ReverseMarkdown.convert(cleaned_body_html, github_flavored: true)
          }
      end

      def remove_language_tag!(comment, language_names)
        language_names.each do |language|
          comment[:body].sub!(/\[[[:punct:]]*language:\s*#{language}[[:punct:]]*\]/i, "")
        end

        comment[:body].strip!

        comment[:replies]&.each do |reply|
          remove_language_tag!(reply, language_names)
        end
      end

      def remove_ids!(comment)
        comment.delete(:id)
        comment.delete(:parent_id)

        comment[:replies].each do |reply|
          remove_ids!(reply)
        end
      end

      def add_missing_replies!(comment, comments, more_childrens, thread_id)
        more_children = more_childrens.find { it[:parent_id] == comment[:id] }
        if more_children
          comments += get_comments_for(thread_id:, parent_id: comment[:id], more_children:)
        end

        children = comments
          .filter { it[:parent_id] == comment[:id] }
          .reject { %w[AutoModerator daggerdragon].include? it[:author] }
          .reject { it[:body].strip == "[removed]" }

        comment[:replies] += children

        children.each do |child|
          add_missing_replies!(child, comments, more_childrens, thread_id)
        end

        comment[:replies].uniq!
      end
    end
  end
end