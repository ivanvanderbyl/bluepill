require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

ROOT_PATH = File.expand_path(File.dirname(__FILE__) + '/tmp')

def app(app_name, options = {}, &block)
  @app = Bluepill::Application.new(app_name.to_s, options, &block)
  @app_methods = Bluepill::DSL::ApplicationMethods.new(@app)
  Blockenspiel.invoke(block, @app_methods)
  
  # @app.load
end

describe 'Blueprint::DSL::ApplicationMethods' do
  it "should check working directory when setting it" do
    lambda {
      app(:my_app, :base_dir => ROOT_PATH) do
        working_dir '/some/non/existant/path'
      end
    }.should raise_exception(Bluepill::InvalidWorkingDirectoryError)
  end
  
  
  
  it "should set application attributes on process" do
    app(:my_app, :base_dir => ROOT_PATH) do
      working_dir ROOT_PATH
      process(:process_1) do
        pid_file "#{name}.pid"
      end
    end
    
    @app.groups[nil].processes[0].name.should == 'process_1'
  end
  
  it "should set process attributes" do
    app(:my_app, :base_dir => ROOT_PATH) do
      process(:my_process) do
        group 'workers'
        start_command 'cd somewhere; start'
        stop_command 'cd somewhere; stop'
        restart_command 'cd somewhere; restart'
        
        stdout 'logs/stdout.log'
        stderr 'logs/stderr.log'
        stdin 'logs/stdin.log'
        
        daemonize true
        pid_file "tmp/pids/#{name}.pid"
        working_dir File.expand_path(File.dirname(__FILE__))
        environment(:RAILS_ENV => 'production')
        
        start_grace_time 20.seconds
        stop_grace_time 10.seconds
        restart_grace_time 30.seconds
        
        uid 'user'
        gid 'group'
                  
        # monitor_children,
        # child_process_template
      end
    end
    
    @app.groups['workers'].processes[0].start_command.should == 'cd somewhere; start'
    @app.groups['workers'].processes[0].stop_command.should == 'cd somewhere; stop'
    @app.groups['workers'].processes[0].restart_command.should == 'cd somewhere; restart'
    
    @app.groups['workers'].processes[0].stdout.should == 'logs/stdout.log'
    @app.groups['workers'].processes[0].stderr.should == 'logs/stderr.log'
    @app.groups['workers'].processes[0].stdin.should == 'logs/stdin.log'
    
    @app.groups['workers'].processes[0].daemonize.should == true
    @app.groups['workers'].processes[0].daemonize?.should == true
    
    @app.groups['workers'].processes[0].pid_file.should == "tmp/pids/my_process.pid"
    @app.groups['workers'].processes[0].working_dir.should == File.expand_path(File.dirname(__FILE__))
    @app.groups['workers'].processes[0].environment.should == {:RAILS_ENV=>"production"}
    
    @app.groups['workers'].processes[0].start_grace_time.should == 20
    @app.groups['workers'].processes[0].stop_grace_time.should == 10
    @app.groups['workers'].processes[0].restart_grace_time.should == 30
    
    @app.groups['workers'].processes[0].uid.should == 'user'
    @app.groups['workers'].processes[0].gid.should == 'group'
  end
  
  it "should set global process attributes" do
    app(:my_app, :base_dir => ROOT_PATH) do
      working_dir File.expand_path(File.dirname(__FILE__))
      
      process(:my_process) do
        group 'workers'
        start_command 'cd somewhere; start'
        stop_command 'cd somewhere; stop'
        restart_command 'cd somewhere; restart'
        
        stdout 'logs/stdout.log'
        stderr 'logs/stderr.log'
        stdin 'logs/stdin.log'
        
        daemonize true
        pid_file "tmp/pids/#{name}.pid"
        
        environment(:RAILS_ENV => 'production')
        
        start_grace_time 20.seconds
        stop_grace_time 10.seconds
        restart_grace_time 30.seconds
        
        uid 'user'
        gid 'group'
                  
        # monitor_children,
        # child_process_template
      end
    end
    
    @app.groups['workers'].processes[0].start_command.should == 'cd somewhere; start'
    @app.groups['workers'].processes[0].stop_command.should == 'cd somewhere; stop'
    @app.groups['workers'].processes[0].restart_command.should == 'cd somewhere; restart'
    
    @app.groups['workers'].processes[0].stdout.should == 'logs/stdout.log'
    @app.groups['workers'].processes[0].stderr.should == 'logs/stderr.log'
    @app.groups['workers'].processes[0].stdin.should == 'logs/stdin.log'
    
    @app.groups['workers'].processes[0].daemonize.should == true
    @app.groups['workers'].processes[0].daemonize?.should == true
    
    @app.groups['workers'].processes[0].pid_file.should == "tmp/pids/my_process.pid"
    @app.groups['workers'].processes[0].working_dir.should == File.expand_path(File.dirname(__FILE__))
    @app.groups['workers'].processes[0].environment.should == {:RAILS_ENV=>"production"}
    
    @app.groups['workers'].processes[0].start_grace_time.should == 20
    @app.groups['workers'].processes[0].stop_grace_time.should == 10
    @app.groups['workers'].processes[0].restart_grace_time.should == 30
    
    @app.groups['workers'].processes[0].uid.should == 'user'
    @app.groups['workers'].processes[0].gid.should == 'group'
  end
  
end