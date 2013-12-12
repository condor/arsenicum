module Arsenicum
  module Sqs
    class Configuration < Arsenicum::Configuration::QueueConfiguration
      attr_config :account, :wait_timeout, :queue_name_prefix,
                  :queue_creation_options
    end
  end
end
