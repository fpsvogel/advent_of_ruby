module DownloadSolutions
  module Api
    class Reddit
      class RemoveLanguageTags
        # Removes language tags from comment bodies.
        #
        # @param params [Reddit::Params]
        # @return [void] params.comments is modified in place.
        def self.call(params:)
          params.comments.each do |comment|
            remove_language_tag!(comment, params.languages)
          end
        end

        private_class_method def self.remove_language_tag!(comment, languages)
          languages.each do |language|
            comment[:body].sub!(/\[[[:punct:]]*language:\s*#{language}[[:punct:]]*\]/i, "")
          end

          comment[:body].strip!

          comment[:replies].each do |reply|
            remove_language_tag!(reply, languages)
          end
        end
      end
    end
  end
end
