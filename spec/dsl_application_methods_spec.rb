require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'Blueprint::DSL::ApplicationMethods' do
  it "should ignore private methods" do
    Bluepill.application(:my_app, :base_dir => File.dirname(__FILE__)) do
      process(:something) do
        
      end
    end
    
    
    
  end
end