module Bluepill
  module DSL
    class ProcessMethods < Base
      attr_reader :attributes, :watches, :name, :app
      dsl_attr_accessor *Bluepill::Process::CONFIGURABLE_ATTRIBUTES
      dsl_attr_accessor :group
      
      def initialize(process_name, app_methods)
        @name = process_name
        @app = app_methods
        @attributes = {}
        @watches = {}
      end
      
      # def method_missing(name, *args)
      #   if args.size == 1 && name.to_s =~ /^(.*)=$/
      #     @attributes[$1.to_sym] = args.first
      #   elsif args.empty? && @attributes.key?(name.to_sym)
      #     @attributes[name.to_sym]
      #   else
      #     super
      #   end
      # end
      
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