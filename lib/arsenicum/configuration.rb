require 'logger'

module Arsenicum
  class Configuration
    module ConfiguredByHash

      def self.included(base)
        base.extend ClassMethods
      end

      def initialize(hash)
        configure(hash)
      end

      private
      def configure(hash)
        @config_keys.each do |key|
          instance_variable_set :"@#{key}", hash[key]
        end
      end

      module ClassMethods
        private
        def attr_config(*attrs)
          @config_keys = Array(attrs)
          @config_keys.each{|key|attr_reader key}
        end
      end
    end

    include Arsenicum::Util

    class << self
      attr_reader :instance

      def configure(values)
        @instance = new(values)
      end
    end

    def initialize(values)
      configs = {}
      normalize_hash(values).each do |key, value|
        case key
          when :queues
            @queue_configurations = value.inject({}) do |h, kv|
              (queue_name, queue_config) = kv
              h.tap do |i|
                i.merge! queue_name => QueueConfiguration.new(queue_name, queue_config)
              end
            end
          when :engine
            @engine = value.to_sym
            @engine_namespace = Arsenicum.const_get(camelcase(@engine))
            @engine_configuration_class = @engine_namespace.const_get(:Configuration)
            @engine_configuration = @engine_configuration_class.new(configs[@engine]) if configs[@engine]
          when @engine
            @engine_configuration = @engine_configuration_class.new(value)
          else
            configs[key] = value
        end
      end
    end

    class QueueConfiguration
      include ConfiguredByHash
      attr_reader :queue_name
      attr_config :methods, :classes, :concurrency

      def initialize(queue_name, queue_config)
        @queue_name = queue_name
        configure(queue_config)
      end
    end

  end
end
