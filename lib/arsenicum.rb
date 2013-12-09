module Arsenicum
  autoload :Version,        'arsenicum/version'
  autoload :Queue,          'arsenicum/queue'
  autoload :Configuration,  'arsenicum/configuration'
  autoload :Syntax,         'arsenicum/syntax'
  autoload :Sqs,            'arsenicum/sqs'
  autoload :CLI,            'arsenicum/cli'
  autoload :Server,         'arsenicum/server'
  autoload :Queueing,       'arsenicum/queueing'
end

if defined? ::ActiveSupport
  ActiveSupport.on_load :active_record do
    Arsenicum::Queueing::Serializer.send :include, Arsenicum::Queueing::Serializer::WithActiveRecord
  end
end
