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
        self.class.config_keys.each do |key|
          instance_variable_set :"@#{key}", hash[key]
        end
      end

      module ClassMethods
        attr_accessor :config_keys
        private
        def attr_config(*attrs)
          @config_keys = Array(attrs)
          @config_keys.each{|key|attr_reader key}
        end
      end
    end

    include Arsenicum::Util

    attr_accessor :queue_configurations, :engine_configuration, :queue_class, :logger,
                  :post_office

    class << self
      attr_reader :instance

      def configure(values)
        @instance = new(values)
      end
    end

    def initialize(values)
      configs = {}
      @logger = Logger.new(STDOUT)

      normalize_hash(values).each do |key, value|
        case key
          when :log_file
            @logger = Logger.new(value)
            @logger.formatter = @log_formatter if @log_formatter
          when :log_format
            @log_formatter = -> severity, datetime, program_name, message { value.freeze }
            @logger.formatter = @log_formatter
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
            @queue_class = @engine_namespace.const_get(:Queue)
            @engine_configuration_class = @engine_namespace.const_get(:Configuration)
            @engine_configuration = @engine_configuration_class.new(configs[@engine]) if configs[@engine]
          when @engine
            @engine_configuration = @engine_configuration_class.new(value)
          else
            configs[key] = value
        end
      end

      @queue_configurations.merge!(default: QueueConfiguration::Default) unless @queue_configurations.include? :default

      @post_office = PostOffice.new self
    end

    class QueueConfiguration
      include ConfiguredByHash
      attr_reader :queue_name
      attr_config :methods, :classes, :concurrency

      DEFAULT_CONCURRENCY = 2

      def initialize(queue_name, queue_config = {})
        @queue_name = queue_name
        configure(queue_config)
        @concurrency ||= DEFAULT_CONCURRENCY
      end

      Default = new(:default)
    end

  end

  class MisconfigurationError < StandardError;end
end
