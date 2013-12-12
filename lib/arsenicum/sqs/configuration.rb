module Arsenicum
  module Sqs
    class Configuration < Arsenicum::Configuration::QueueConfiguration
      attr_config :account, :wait_timeout, :queue_creation_options
    end
  end
end
