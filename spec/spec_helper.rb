$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require "active_support"

require 'bluepill'
require 'spec'
require 'spec/autorun'

RSpec.configure do |config|
end
