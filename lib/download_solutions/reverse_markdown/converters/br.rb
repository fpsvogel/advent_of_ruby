# Monkeypatch. Reason: "  \n" is rendered as a line break by Markdown viewers,
# but trailing spaces are annoying and I strip them out because that's what my
# editor does on save anyway. Which leaves only the newline, which is rendered
# as a space. So it's preferable for <br> to become a paragraph break.
module ReverseMarkdown
  module Converters
    class Br < Base
      def convert(node, state = {})
        "\n\n" # CHANGED from "  \n"
      end
    end

    register :br, Br.new
  end
end
