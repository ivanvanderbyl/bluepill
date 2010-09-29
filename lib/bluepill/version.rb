module Bluepill
  VERSION = File.read(File.join(File.dirname(__FILE__), '../..', 'VERSION')).to_s.strip.freeze
end