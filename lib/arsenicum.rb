module Arsenicum
  autoload :CLI,            'arsenicum/cli'
  autoload :Configuration,  'arsenicum/configuration'
  autoload :Processing,     'arsenicum/processing'
  autoload :Queue,          'arsenicum/queue'
  autoload :Queueing,       'arsenicum/queueing'
  autoload :Sqs,            'arsenicum/sqs'
  autoload :Syntax,         'arsenicum/syntax'
  autoload :Util,           'arsenicum/util'
  autoload :Version,        'arsenicum/version'
end

if defined? ::ActiveSupport
  ActiveSupport.on_load :active_record do
    Arsenicum::Queueing::Serializer.send :include, Arsenicum::Queueing::Serializer::WithActiveRecord
  end
end
