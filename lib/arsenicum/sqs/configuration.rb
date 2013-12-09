module Arsenicum
  module Sqs
    class Configuration
      include Arsenicum::Configuration::ConfiguredByHash

      attr_config :account
    end
  end
end