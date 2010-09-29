module Bluepill
  module DSL
    class Base
      include Blockenspiel::DSL
      
      attr_accessor :working_dir, :uid, :gid, :environment
      
      class << self
        def require_attribute(*attributes)
          
        end
      end
      
    end
  end
end