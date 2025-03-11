module DownloadSolutions
  module Api
    class Reddit
      class AddMissingReplies
        # Fetches replies to comments that are not yet loaded, only listed in
        # "more children" nodes.
        #
        # @param params [Reddit::Params]
        # @return [void] params.comments is modified in place.
        def self.call(params:)
          params.comments.each do |comment|
            add_missing_replies!(comment, params)
          end

          params.comments.reject! do |comment|
            comment[:parent_id] != params.thread_id
          end
        end

        private_class_method def self.add_missing_replies!(comment, params)
          comments_from_more_children, more_children_from_more_children =
            GetSerialComments.call(
              params:,
              parent_id: comment[:id]
            )
          params.original_comments += comments_from_more_children
          debugger unless more_children_from_more_children.empty?
          params.original_comments += more_children_from_more_children

          children = params.original_comments.filter { it[:parent_id] == comment[:id] }

          comment[:replies] += children

          children.each do |child|
            add_missing_replies!(child, params)
          end

          comment[:replies].uniq!
        end
      end
    end
  end
end
