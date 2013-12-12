module Arsenicum
  module Sqs
    class Configuration
      include Arsenicum::Configuration::ConfiguredByHash
      attr_config :account, :queue_name_prefix, :queue_creation_options
    end
  end
end
