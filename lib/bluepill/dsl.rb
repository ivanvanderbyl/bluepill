module Bluepill
  module DSL
    # :nodoc
  end
  
  class << self
    # Creates an application to monitor
    def application(app_name, options = {}, &block)
      $stdout.print "===> Loading application: #{app_name}..."
      
      app = Application.new(app_name.to_s, options, &block)
      Blockenspiel.invoke(block, DSL::ApplicationMethods.new(app))
      
      $stdout.print " Complete.\n"
      
      app.load
    rescue DSLConfigError => e
      $stderr.puts " Failed.\n"
      $stderr.puts "Config error: #{e.message}"
      exit(6)
    end
  end
end
