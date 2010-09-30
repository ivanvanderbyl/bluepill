module Bluepill
  module DSL
    class ProcessMethods < Base
      attr_reader :attributes, :watches, :name, :app
      
      dsl_attr_accessor *Bluepill::Process::CONFIGURABLE_ATTRIBUTES
      
      def initialize(process_name, app_methods)
        @name = process_name
        @app = app_methods
        @attributes = {}
        @watches = {}
      end
      
      dsl_method :validate!, false
      
      # Validates the DSL for this process
      def validate!
        # validate uniqueness of group:process
        process_key = [self.group, self.name].join(":")
        if self.app.process_keys.key?(process_key)
          raise DuplicateProcessNameError, %(
You have two entries for the process name '#{name}'
in the group '#{self.group}'
) unless self.group.nil?
        else
          self.app.process_keys[process_key] = 0
        end
        
        # Validate existence working directory, if given
        unless self.working_dir.nil?
          raise InvalidWorkingDirectoryError, "Working directory '#{self.working_dir}' doesn't exist" unless File.directory?(self.working_dir)
        end
        
        # validate required attributes, start_command and pid_file
        [:start_command, :pid_file].each do |required_attr|
          if self.send(required_attr).blank?
            raise MissingRequiredAttributeError, "You must specify a #{required_attr} for '#{name}'"
          end
        end
        
        # validate uniqueness of pid files
        pid_key = self.pid_file.strip
        if self.app.pid_files.key?(pid_key)
          raise DuplicatePidFileError, "You have multiple entries with the pid file: '#{self.pid_file}'. You must specify a unique pid file for each process."
        else
          self.app.pid_files[pid_key] = 0
        end
        
      end
      
      def assign_process_attributes!
        Bluepill::Process::CONFIGURABLE_ATTRIBUTES.each do |attribute|
          @attributes[attribute] = self.send(attribute) 
        end
      end
      
      def checks(name, options = {})
        @watches[name] = options
      end
      
      def validate_child_process(child)
        unless child.attributes.has_key?(:stop_command)
          $stderr.puts "Config Error: Invalid child process monitor for #{@name}"
          $stderr.puts "You must specify a stop command to monitor child processes."
          exit(6)
        end
      end
      
      def create_child_process_template
        if @child_process_block
          child_proxy = self.class.new
          # Children inherit some properties of the parent
          [:start_grace_time, :stop_grace_time, :restart_grace_time].each do |attribute|
            child_proxy.send("#{attribute}=", @attributes[attribute]) if @attributes.key?(attribute)
          end
          @child_process_block.call(child_proxy)
          validate_child_process(child_proxy)
          @attributes[:child_process_template] = child_proxy.to_process(nil)
        end
      end
      
      def monitor_children(&child_process_block)
        @child_process_block = child_process_block
        @attributes[:monitor_children] = true
      end
      
      def to_process(process_name)
        process = Bluepill::Process.new(process_name, @attributes)
        @watches.each do |name, opts|
          if Bluepill::Trigger[name]
            process.add_trigger(name, opts)
          else
            process.add_watch(name, opts)
          end
        end

        process
      end
      
    end
  end
end