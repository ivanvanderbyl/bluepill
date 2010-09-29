module Bluepill
  module DSL
    # :nodoc
  end
  
  class << self
    def application(app_name, options = {}, &block)
      app = Application.new(app_name.to_s, options, &block)
      
      
    end
  end
end