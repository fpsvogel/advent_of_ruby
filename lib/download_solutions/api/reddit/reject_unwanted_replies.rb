module DownloadSolutions
  module Api
    class Reddit
      class RejectUnwantedReplies
        # Filters out replies that are not gennerally relevant for posterity:
        #   - removed/deleted with no replies
        #   - by moderators
        #   - by bots
        #
        # @param params [Reddit::Params]
        # @return [void] params.comments is modified in place.
        def self.call(params:)
          params.comments.each do |comment|
            reject_unwanted_replies!(comment)
          end
        end

        private_class_method def self.reject_unwanted_replies!(comment)
          comment[:replies].each do |reply|
            reject_unwanted_replies!(reply)
          end

          comment[:replies].reject! do
            (["[removed]", "[deleted]"].include?(it[:body].strip) && it[:replies].empty?) ||
              %w[AutoModerator daggerdragon backtickbot].include?(it[:author])
          end
        end
      end
    end
  end
end
