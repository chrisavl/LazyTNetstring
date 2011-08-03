$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rspec'
require 'tnetstring'
require 'lazy_tnetstring'

RSpec.configure do |config|
  config.mock_with :rspec
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each {|f| require f}
