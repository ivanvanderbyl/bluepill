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
        working_dir '/some/non/existent/path'
        process(:my_process_1) do
          pid_file      "tmp/pids/#{name}.pid"
          start_command 'start'
        end
      end
    }.should raise_exception(Bluepill::InvalidWorkingDirectoryError)
    
    lambda {
      app(:my_app_1, :base_dir => ROOT_PATH) do
        process(:my_process_1) do
          pid_file      "tmp/pids/#{name}.pid"
          start_command 'start'
          working_dir   '/some/non/existent/path'
        end
      end
    }.should raise_exception(Bluepill::InvalidWorkingDirectoryError)
  end
  
  it "should validate presence of pid_file" do
    lambda {
      app(:my_app_1, :base_dir => ROOT_PATH) do
        process(:my_process_1) do
          # pid_file      "tmp/pids/#{name}.pid"
          start_command 'start'
          working_dir   ROOT_PATH
        end
      end
    }.should raise_exception(Bluepill::MissingRequiredAttributeError)
  end
  
  it "should validate uniqueness of pid_file" do
    lambda {
      app(:my_app_1, :base_dir => ROOT_PATH) do
        process(:my_process_1) do
          pid_file      "tmp/pids/my_process_1.pid"
          start_command 'start'
          working_dir   ROOT_PATH
        end
        
        process(:my_process_2) do
          pid_file      "tmp/pids/my_process_1.pid"
          start_command 'start'
          working_dir   ROOT_PATH
        end
      end
    }.should raise_exception(Bluepill::DuplicatePidFileError)
  end
  
  it "should validate uniqueness of process name and group" do
    lambda {
      app(:my_app_1, :base_dir => ROOT_PATH) do
        process(:my_process_1) do
          group         'workers'
          pid_file      "tmp/pids/my_process_1.pid"
          start_command 'start'
          working_dir   ROOT_PATH
        end
        
        process(:my_process_1) do
          group         'workers'
          pid_file      "tmp/pids/my_process_2.pid"
          start_command 'start'
          working_dir   ROOT_PATH
        end
      end
    }.should raise_exception(Bluepill::DuplicateProcessNameError)
  end
  
  it "should validate requirement of start_command" do
    lambda {
      app(:my_app_1, :base_dir => ROOT_PATH) do
        process(:my_process_1) do
          # pid_file      "tmp/pids/#{name}.pid"
          # start_command 'start'
          working_dir   ROOT_PATH
        end
      end
    }.should raise_exception(Bluepill::MissingRequiredAttributeError)
  end
  
  it "should set application attributes on process" do
    app(:my_app, :base_dir => ROOT_PATH) do
      working_dir ROOT_PATH
      process(:process_1) do
        pid_file "#{name}.pid"
        start_command 'start'
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
      uid 'user'
      gid 'group'
      environment(:RAILS_ENV => 'production')
      
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
        
        start_grace_time 20.seconds
        stop_grace_time 10.seconds
        restart_grace_time 30.seconds
        
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