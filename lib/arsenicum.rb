module Arsenicum
  autoload  :Configuration,         'arsenicum/configuration'
  autoload  :MisconfigurationError, 'arsenicum/configuration'
  autoload  :Core,                  'arsenicum/core'
  autoload  :Util,                  'arsenicum/util'
  autoload  :Version,               'arsenicum/version'
  autoload  :Serializer,            'arsenicum/serializer'
  autoload  :Formatter,             'arsenicum/formatter'
  autoload  :Async,                 'arsenicum/async'
  autoload  :Main,                  'arsenicum/main'

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
