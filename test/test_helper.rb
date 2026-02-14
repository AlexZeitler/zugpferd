require "bundler/setup"
require "minitest/autorun"
require "zugpferd"
require "nokogiri"

Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

SCHEMAS_PATH = ENV.fetch(
  "SCHEMAS_PATH",
  File.expand_path("../vendor/schemas", __dir__)
)

TESTSUITE_PATH = ENV.fetch(
  "XRECHNUNG_TESTSUITE_PATH",
  File.expand_path("../vendor/testsuite", __dir__)
)
