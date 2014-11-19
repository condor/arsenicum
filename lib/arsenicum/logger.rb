require 'logger'

module Arsenicum::Logger
  class << self
    attr_reader :logger

    def configure(logger_config)
      @logger = logger_config.build
    end

    [:debug, :info, :warn, :error, :fatal].each do |method|
      eval <<-METHOD, binding, __FILE__, __LINE__ + 1
        def #{method}(*args, &block)
          return unless logger
          logger.#{method}(*args, &block)
        end
      METHOD
    end
  end
end
