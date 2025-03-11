module DownloadSolutions
  module Api
    class Reddit
      class FilterByLanguage
        # Filters comments by the desired programming language(s).
        #
        # @param params [Reddit::Params]
        # @return [Array<Hash>]
        def self.call(params:)
          params.original_comments.filter { |comment|
            comment_body = comment[:body]&.downcase
            next unless comment_body

            language_specified = comment_body.match?(/\[[[:punct:]]*language:/i)

            if language_specified
              params.languages.any? { |language|
                comment_body.match?(/\[[[:punct:]]*language:\s*#{language}/i)
              }
            else
              params.languages.any? { |language|
                # "sh:" because of "<pre class=\"brush:ruby", see:
                # https://github.com/xijo/reverse_markdown/blob/14d53d5f914fd926b49e6492fd7bd95e62ef541a/lib/reverse_markdown/converters/pre.rb#L37
                comment_body.match?(/(?<!```|sh:)#{language}/i)
              }
            end
          }
        end
      end
    end
  end
end
