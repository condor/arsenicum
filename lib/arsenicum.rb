require 'celluloid'
require 'msgpack'

module Arsenicum
  autoload  :Backend,               'arsenicum/backend'
  autoload  :BootStrap,             'arsenicum/bootstrap'
  autoload  :Configuration,         'arsenicum/configuration'
  autoload  :MisconfigurationError, 'arsenicum/configuration'
  autoload  :Logger,                'arsenicum/logger'
  autoload  :Queue,                 'arsenicum/queue'
  autoload  :Server,                'arsenicum/server'
  autoload  :Util,                  'arsenicum/util'
  autoload  :Version,               'arsenicum/version'
end
