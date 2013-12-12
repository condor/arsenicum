module Arsenicum
  autoload :CLI,                    'arsenicum/cli'
  autoload :Configuration,          'arsenicum/configuration'
  autoload :MisconfigurationError,  'arsenicum/configuration'
  autoload :Mock,                   'arsenicum/mock'
  autoload :Processing,             'arsenicum/processing'
  autoload :Queue,                  'arsenicum/queue'
  autoload :QueueImplementation,    'arsenicum/queue_implementation'
  autoload :Queueing,               'arsenicum/queueing'
  autoload :Sqs,                    'arsenicum/sqs'
  autoload :Syntax,                 'arsenicum/syntax'
  autoload :Util,                   'arsenicum/util'
  autoload :Version,                'arsenicum/version'

  class << self
    def configure(arg = nil, &block)
      Arsenicum::Configuration.configure arg, &block
    end

    def configuration
      Configuration.instance
    end

    alias_method :config, :configuration
  end
end

if defined? ::ActiveSupport
  ActiveSupport.on_load :active_record do
    Arsenicum::Queueing::Serializer.send :include, Arsenicum::Queueing::Serializer::WithActiveRecord
  end
end
