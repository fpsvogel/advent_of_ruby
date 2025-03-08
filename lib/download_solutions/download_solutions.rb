require "debug"
require "dotenv"
require "faraday"
require "faraday/retry"
require "pastel"
require "redcarpet"
require "reverse_markdown"
require "yaml"
require_relative "../arb/version"

module DownloadSolutions
  InputError = Class.new(StandardError)
  PASTEL = Pastel.new
end

Dir[File.join(__dir__, "**", "*.rb")].each do |file|
  require file
end
