module Bluepill
  module DSL
    class Base
      include Blockenspiel::DSL
            
      # Global attributes, which will be passed to each process
      # These can be set under application or process, with subsequent levels overriding the parent value.
      dsl_attr_accessor :working_dir, :uid, :gid, :environment
      
      class << self
        def require_attribute(*attributes)
          # TBI
        end
      end
      
    end
  end
end