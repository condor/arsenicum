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
