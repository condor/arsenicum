require 'celluloid'

module Arsenicum
  autoload :Version,        'arsenicum/version'
  autoload :Queue,          'arsenicum/queue'
  autoload :Task,           'arsenicum/task'
  autoload :Configuration,  'arsenicum/configuration'
  autoload :Serialization,  'arsenicum/serialization'
  autoload :WatchDog,       'arsenicum/watchdog'
  autoload :QueueProxy,     'arsenicum/queue_proxy'
  autoload :Syntax,         'arsenicum/syntax'
  autoload :Sqs,            'arsenicum/sqs'
  autoload :CLI,            'arsenicum/cli'
  autoload :Server,         'arsenicum/server'
  autoload :Actor,          'arsenicum/actor'
end
