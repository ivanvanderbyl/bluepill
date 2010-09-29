module Bluepill
  module DSL
    # :nodoc
  end
  
  class << self
    # Creates an application to monitor
    def application(app_name, options = {}, &block)
      $stdout.print "===> Loading application #{app_name}..."
      
      app = Application.new(app_name.to_s, options, &block)
      Blockenspiel.invoke(block, DSL::ApplicationMethods.new(app))
      app.load
      
      $stdout.print "===> Done."
    rescue => e
      $stderr.puts "DSL implementation error: #{e.message}"
      exit(1)
    end
  end
end
