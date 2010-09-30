require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
include Bluepill

def application(app_name, options = {}, &block)
  options = {
    :base_dir => File.dirname(__FILE__)
  }.update(options)
  $stdout.puts "===> Loading application: #{app_name}..."
  
  app = Application.new(app_name.to_s, options, &block)
  Blockenspiel.invoke(block, DSL::ApplicationMethods.new(app))
  
  app.load
end

def process(name, &block)
  @app_methods = Bluepill::DSL::ApplicationMethods.new(app)
  @process_proxy = Bluepill::DSL::ProcessMethods.new(name,app)
  Blockenspiel.invoke(block, @process_proxy)
end

describe "Bluepill::DSL" do
  before do
    @process_proxy = nil
  end
  
  describe "ApplicationMethods" do
    it "should check working directory when setting it" do
      lambda { 
        application('myapp') do
          working_dir '/some/non/existant/path'
        end 
      }.should raise_exception
    end
    
    it "should set attributes" do
      application('myapp') do
        uid "deploy"
        gid "deploy"
      end

      # @app_methods.app.name.should == 'myapp'
      @app_methods.uid.should == 'deploy'
      @app_methods.gid.should == 'deploy'
    end
    
    it "should support setting attributes in old style" do
      application('myapp') do |app|
        app.uid = "deploy"
        app.gid = "deploy"
        app.environment = 'production'
      end

      @app_methods.app.name.should == 'myapp'
      @app_methods.uid.should == 'deploy'
      @app_methods.gid.should == 'deploy'
      @app_methods.environment.should == 'production'
    end
    
    it "should assign pids_dir to application" do
      application('myapp') do |app|
        app.working_dir = File.expand_path(File.dirname(__FILE__))
        app.pids_dir = "#{app.working_dir}/pids"
      end

      @app_methods.app.pids_dir.should == File.expand_path(File.dirname(__FILE__) + '/pids/')
    end
    
    it "should pass app level attributes to processes" do
      application('myapp') do
        uid  "deploy"
        gid "deploy"
        
        process(:delayed_job) do
          start_command 'start'
          gid "www"
        end
      end

      @app_methods.uid.should == 'deploy'
      @app_methods.gid.should == 'deploy'
      @app_methods.app.groups[nil].processes[0].uid.should == 'deploy'
      @app_methods.app.groups[nil].processes[0].gid.should == 'www'
    end
    
  end
  
  describe "ProcessMethods" do
    it "should assign attributes using proc.attr" do
      process("delayed_job") do |proc|
        proc.start_grace_time = 40.seconds
      end
      
      @process_proxy.name.should == 'delayed_job'
      @process_proxy.start_grace_time.should == 40.seconds
      @process_proxy.attributes.should == {:start_grace_time => 40.seconds}
    end
    
    it "should assign attributes using methods" do
      process("delayed_job") do
        start_grace_time 40.seconds
        # working_dir '/somewhere'
      end
      
      @process_proxy.name.should == 'delayed_job'
      @process_proxy.start_grace_time.should == 40.seconds
      @process_proxy.attributes.should == {:start_grace_time => 40.seconds}
    end
    
    it "should assign group" do
      process("delayed_job") do
        start_grace_time 40.seconds
        group 'workers'
      end
      
      @process_proxy.name.should == 'delayed_job'
      @process_proxy.group.should == 'workers'
    end
    
    it "should set process attributes" do
      application(:my_app) do
        process(:my_process) do
          group 'workers'
          start_command 'cd somewhere; start'
          stop_command 'cd somewhere; stop'
          restart_command 'cd somewhere; restart'
          
          stdout 'logs/stdout.log'
          stderr 'logs/stderr.log'
          stdin 'logs/stdin.log'
          
          should_daemonize false
          pid_file "tmp/pids/#{name}.pid"
          working_dir File.expand_path(File.dirname(__FILE__))
          environment(:rails_env => 'production')
          
          start_grace_time 20.seconds
          stop_grace_time 10.seconds
          restart_grace_time 30.seconds
          
          uid 'user'
          gid 'group'
                    
          # monitor_children,
          # child_process_template
        end
      end
      
      @app_methods.app.groups['workers'].processes[0].group.should == 'workers'
      @app_methods.app.groups['workers'].processes[0].start_command.should == 'cd somewhere; start'
      @app_methods.app.groups['workers'].processes[0].stop_command.should == 'cd somewhere; stop'
      @app_methods.app.groups['workers'].processes[0].restart_command.should == 'cd somewhere; restart'
      
      @app_methods.app.groups['workers'].processes[0].stdout.should == 'logs/stdout.log'
      @app_methods.app.groups['workers'].processes[0].stderr.should == 'logs/stderr.log'
      @app_methods.app.groups['workers'].processes[0].stdin.should == 'logs/stdin.log'
      
      @app_methods.app.groups['workers'].processes[0].should_daemonize.should == false
      
      @app_methods.app.groups['workers'].processes[0].pid_file.should == "tmp/pids/my_process.pid"
      @app_methods.app.groups['workers'].processes[0].working_dir.should == File.expand_path(File.dirname(__FILE__))
      @app_methods.app.groups['workers'].processes[0].environment.should == {:rails_env=>"production"}
      
      @app_methods.app.groups['workers'].processes[0].start_grace_time.should == 20
      @app_methods.app.groups['workers'].processes[0].stop_grace_time.should == 10
      @app_methods.app.groups['workers'].processes[0].restart_grace_time.should == 30
      
      @app_methods.app.groups['workers'].processes[0].uid.should == 'user'
      @app_methods.app.groups['workers'].processes[0].gid.should == 'group'
    end
  end
end