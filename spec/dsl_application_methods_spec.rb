require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'Blueprint::DSL::ApplicationMethods' do
  it "should ignore private methods" do
    lambda { 
      Bluepill.application(:my_app, :base_dir => File.dirname(__FILE__)) do
        process(:process_1) do
          pid_file "#{name}.pid"
        end
      end      
    }.should raise_error(Exception)
    
      
  end
end