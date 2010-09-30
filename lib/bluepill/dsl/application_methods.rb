module Bluepill
  module DSL
    class ApplicationMethods < Base
      attr_accessor :app, :pid_files, :process_keys
      
      def initialize(app)
        self.app = app
        self.pid_files = {}
        self.process_keys = {}
      end
      
      # Creates a new process to monior
      def process(process_name, &block)
        process_proxy = ProcessMethods.new(process_name.to_s, self)
        
        # Assigns all attributes from application scope and assigns to process
        assign_global_attributes(process_proxy)
        
        Blockenspiel.invoke(block, process_proxy)
        # Takes everything which we set in the DSL and loads it into @attributes
        process_proxy.assign_process_attributes!
        
        process_proxy.create_child_process_template
        
        assign_default_pid_file(process_proxy, process_name.to_s)
        
        # Validate process
        process_proxy.validate!
        
        # Assign group to process
        process = process_proxy.to_process(process_name.to_s)
        
        self.app.add_process(process)
      end
      
      # :nodoc
      def assign_global_attributes(process_proxy)
        Bluepill::Process::GLOBAL_ATTRIBUTES.each do |attribute|
          process_proxy.send("#{attribute}=", self.send(attribute))
        end
      end
      
      # :nodoc
      def assign_default_pid_file(process_proxy, process_name)
        unless process_proxy.attributes.key?(:pid_file)
          group_name = process_proxy.attributes["group"]
          default_pid_name = [group_name, process_name].compact.join('_').gsub(/[^A-Za-z0-9_\-]/, "_")
          process_proxy.pid_file = File.join(self.app.pids_dir, default_pid_name + ".pid")
        end
      end
      
    end
  end
end