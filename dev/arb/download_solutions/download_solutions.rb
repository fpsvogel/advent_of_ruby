require "debug"
require "dotenv"
require "faraday"
require "faraday/retry"
require "pastel"
require "redcarpet"
require "reverse_markdown"
require "yaml"
require "arb/version"
require "arb/util"

module Arb
  module DownloadSolutions
    InputError = Class.new(StandardError)
    PASTEL = Pastel.new
  end
end

Dir[File.join(__dir__, "**", "*.rb")].each do |file|
  require file
end
