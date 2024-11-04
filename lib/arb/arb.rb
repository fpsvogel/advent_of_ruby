require "benchmark"
require "date"
require "debug"
require "dotenv"
require "faraday"
require "open3"
require "pastel"
require "reverse_markdown"
require "rspec/core"

class AppError < StandardError; end
class InputError < AppError; end
class ConfigError < AppError; end

PASTEL = Pastel.new

Dir[File.join(__dir__, "**", "*.rb")].each do |file|
  require file
end
