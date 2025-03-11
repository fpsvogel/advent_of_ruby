module DownloadSolutions
  module Api
    class Reddit
      class CleanBodies
        MARKDOWN_PARSER = Redcarpet::Markdown.new(Redcarpet::Render::HTML, fenced_code_blocks: true)

        # Clean and format comment bodies.
        #
        # @param params [Reddit::Params]
        # @return [void] params.comments is modified in place.
        def self.call(params:)
          params.comments.each do |comment|
            clean_body!(comment, params.languages)
          end
        end

        private_class_method def self.clean_body!(comment, languages)
          precleaned_markdown = comment[:body]
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

          html = MARKDOWN_PARSER.render(precleaned_markdown)

          cleaned_markdown = html
            # https://github.com/xijo/reverse_markdown/blob/14d53d5f914fd926b49e6492fd7bd95e62ef541a/lib/reverse_markdown/converters/pre.rb#L37
            .gsub("<pre>", "<pre class=\"brush:#{languages.first};\">")
            .gsub(/<pre><code class=([^>]+)>/, "<pre class=\\1><code>")
            .then { |cleaned_raw_body|
              ReverseMarkdown.convert(cleaned_raw_body, github_flavored: true)
            }
            .gsub(/ +\n/, "\n") # Strip trailing spaces

          comment[:body] = cleaned_markdown

          comment[:replies].each do |reply|
            clean_body!(reply, languages)
          end
        end
      end
    end
  end
end
