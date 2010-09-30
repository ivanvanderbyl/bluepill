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
        set_app_wide_attributes(process_proxy)
        Blockenspiel.invoke(block, process_proxy)
        process_proxy.assign_process_attributes!
        
        process_proxy.create_child_process_template
        
        assign_default_pid_file(process_proxy, process_name.to_s)
        validate_process(process_proxy, process_name.to_s)
        
        group = process_proxy.attributes.delete(:group)
        process = process_proxy.to_process(process_name.to_s)
        
        self.app.add_process(process, group)
      end
      
      # Exclude these methods from being callable from within the DSL (using paramerless blocks)
      # A bit like making them private in a class.
      dsl_method :validate_process, false
      dsl_method :set_app_wide_attributes, false
      dsl_method :assign_default_pid_file, false
      
      def validate_process(process, process_name)
        # validate uniqueness of group:process
        process_key = [process.attributes[:group], process_name].join(":")
        if self.process_keys.key?(process_key)
          $stderr.print "Config Error: You have two entries for the process name '#{process_name}'"
          $stderr.print " in the group '#{process.attributes[:group]}'" if process.attributes.key?(:group)
          $stderr.puts
          exit(6)
        else
          self.process_keys[process_key] = 0
        end
        
        # validate required attributes
        [:start_command].each do |required_attr|
          if !process.attributes.key?(required_attr)
            $stderr.puts "Config Error: You must specify a #{required_attr} for '#{process_name}'"
            exit(6)
          end
        end
        
        # validate uniqueness of pid files
        pid_key = process.pid_file.strip
        if self.pid_files.key?(pid_key)
          $stderr.puts "Config Error: You have two entries with the pid file: #{process.pid_file}"
          exit(6)
        else
          self.pid_files[pid_key] = 0
        end
      end
      
      def set_app_wide_attributes(process_proxy)
        Bluepill::Process::GLOBAL_ATTRIBUTES.each do |attribute|
          unless process_proxy.attributes.key?(attribute)
            process_proxy.attributes[attribute] = self.send(attribute)
          end
        end
      end
      
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