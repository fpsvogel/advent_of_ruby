module DownloadSolutions
  module Api
    class Reddit
      class RemoveIds
        # Removes IDs from comments.
        #
        # @param params [Reddit::Params]
        # @return [void] params.comments is modified in place.
        def self.call(params:)
          params.comments.each do |comment|
            remove_ids!(comment)
          end
        end

        private_class_method def self.remove_ids!(comment)
          comment.delete(:id)
          comment.delete(:parent_id)

          comment[:replies].each do |reply|
            remove_ids!(reply)
          end
        end
      end
    end
  end
end
