module DownloadSolutions
  module Api
    class Reddit
      class CleanBodies
        MARKDOWN_PARSER = Redcarpet::Markdown.new(Redcarpet::Render::HTML, fenced_code_blocks: true)

        # Clean up comment bodies by removing unwanted characters, translating
        # encoded characters, and standardizing to fenced (triple backtick) code
        # blocks.
        #
        # @param params [Reddit::Params]
        # @return [void] params.comments is modified in place.
        def self.call(params:)
          params.comments.each do |comment|
            clean_body!(comment, params.languages)
          end
        end

        private_class_method def self.clean_body!(comment, languages)
          debugger if comment[:author] == "doromin"
          comment[:body] = preclean_markdown(comment[:body], languages)
            .then { |body_markdown| MARKDOWN_PARSER.render(body_markdown) }
            .then { |body_html| to_cleaned_markdown(body_html, languages) }

          comment[:replies].each do |reply|
            clean_body!(reply, languages)
          end
        end

        private_class_method def self.preclean_markdown(initial_body_markdown, languages)
          initial_body_markdown
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
              /\\?`(?:\\?`)?(?:#{languages.first})?\n+(.+?)\n\\?`(?:\\?`)?(?=\n|\z)/m,
              "\n\n```\n\\1\n```\n"
            )
            .gsub(/    ```.*/, "") # Superfluous backticks (already indented)
            # Add an empty line above code blocks, if missing.
            .gsub(/\n{0,2}```(?:#{languages.first})?/, "\n\n```")
        end

        private_class_method def self.to_cleaned_markdown(body_html, languages)
          body_html
            # https://github.com/xijo/reverse_markdown/blob/14d53d5f914fd926b49e6492fd7bd95e62ef541a/lib/reverse_markdown/converters/pre.rb#L37
            .gsub("<pre>", "<pre class=\"brush:#{languages.first};\">")
            .gsub(/<pre><code class=([^>]+)>/, "<pre class=\\1><code>")
            .then { |cleaned_raw_body|
              ReverseMarkdown.convert(cleaned_raw_body, github_flavored: true)
            }
            .gsub(/ +\n/, "\n") # Strip trailing spaces
            .sub(/```ruby\n{2,}/, "```ruby\n") # Remove leading newlines from code blocks
            .sub(/\n{2,}```$/, "\n```") # Remove trailing newlines from code blocks
        end
      end
    end
  end
end
