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
      # @return [Array<Hash>]
      #
      # @raise [MaxSleepCountReachedError] if Reddit seemingly throttled for an
      #   unusually long time, "seemingly" because the only sign is an empty
      #   JSON response body after loading additional comments.
      # @raise [MultipleMoreChildrensError] if there are multiple "more children"
      #   nodes for the thread or a comment; only one at a time is expected.
      def get_comments(year:, day:, languages:)
        params = Params.new(year:, day:, languages:, connection:)

        params.initial_response = GetInitialResponse.call(params:)
        # Keep unfetched replies ("more children" nodes) separate so that after
        # filtering, the replies to filtered-in comments can then be fetched.
        params.original_comments, params.more_childrens = GetSerialComments.call(params:)
        params.comments = FilterByLanguage.call(params:)

        # These operations modify params#comments in place.
        AddMissingReplies.call(params:)
        RejectUnwantedReplies.call(params:)
        CleanBodies.call(params:)
        RemoveLanguageTags.call(params:)
        RemoveIds.call(params:)

        params.comments
      end

      private

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

        response.body["access_token"]
      end
    end
  end
end
