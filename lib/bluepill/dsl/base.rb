module Bluepill
  module DSL
    class Base
      include Blockenspiel::DSL
            
      # Global attributes, which will be passed to each process
      # These can be set under application or process, with subsequent levels overriding the parent value.
      dsl_attr_accessor *Bluepill::Process::GLOBAL_ATTRIBUTES
      
      def working_dir=(str)
        @working_dir = str
        raise InvalidWorkingDirectoryError, "Working directory doesn't exist" unless File.directory?(self.working_dir)
      # rescue => e
      #   $stderr.puts e.message
      #   exit(1)
      end
      
      attr_reader :working_dir
      dsl_method :working_dir, :working_dir=
      
      class << self
        def require_attribute(*attributes)
          # TBI
        end
      end
      
    end
  end
end