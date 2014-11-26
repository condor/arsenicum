require 'logger'

module Arsenicum::Logger
  class << self
    attr_reader :logger

    def set_logger(logger)
      @logger = logger
    end

    [:debug, :info, :warn, :error, :fatal].each do |method|
      eval <<-METHOD, binding, __FILE__, __LINE__ + 1
        def #{method}(&block)
          return unless logger
          logger.#{method} &block
        end
      METHOD
    end
  end
end
