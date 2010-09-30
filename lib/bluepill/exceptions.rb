module Bluepill
  class GenericError < Exception; end
  class DSLConfigError < Exception; end
  
  class InvalidWorkingDirectoryError < DSLConfigError; end
  class DuplicateProcessNameError < DSLConfigError; end
  class DuplicatePidFileError < DSLConfigError; end
  class UnableToWritePidFileError < DSLConfigError; end
  class MissingRequiredAttributeError < DSLConfigError; end
end