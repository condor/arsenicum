require 'celluloid'
require 'msgpack'

module Arsenicum
  autoload  :Configuration,         'arsenicum/configuration'
  autoload  :MisconfigurationError, 'arsenicum/configuration'
  autoload  :Core,                  'arsenicum/core'
  autoload  :Util,                  'arsenicum/util'
  autoload  :Version,               'arsenicum/version'
  autoload  :Serializer,            'arsenicum/serializer'
  autoload  :Formatter,             'arsenicum/formatter'
  autoload  :Queue,                 'arsenicum/queue'
  autoload  :Main,                  'arsenicum/main'
  autoload  :IO,                    'arsenicum/io'
  autoload  :Task,                  'arsenicum/task'
  autoload  :Routing,               'arsenicum/routing'
  autoload  :Logger,                'arsenicum/logger'
  autoload  :CLI,                   'arsenicum/cli'
end
