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
                  :post_office, :server

    class << self
      attr_reader :instance

      def configure(arg)
        config_values =
            if block_given?
              value_holder = TopLevelValueHolder.new
              yield(value_holder)
              value_holder.to_h
            else
              case arg
                when String
                  if arg.end_with? '.rb'
                    load arg
                    nil # because configuration is expected to be finished in the loaded script.
                  else
                    YAML.load(File.read arg, encoding: 'UTF-8')
                  end
                when IO
                  YAML.load arg.read
                when Hash
                  arg
                else
                  raise ArgumentError, 'configure should be called: with arg - any of [String(config file path), IO, Hash] - , or block'
              end
            end
        # The case where the config values is nil occurs only given arg is '*.rb',
        #   which means that configuration by Ruby script is expected to be completed in the script.
        #   That script will call configure with block.
        @instance = new(config_values) if config_values
        @instance
      end
    end

    def initialize(values)
      configs = {}
      @logger = Logger.new(STDOUT)

      normalize_hash(values).each do |key, value|
        case key
          when :server
            @server = ServerConfiguration.new(value)
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

      @queue_configurations ||= {}
      @queue_configurations.merge!(default: QueueConfiguration::Default) unless
          @queue_configurations.include?(:default)

      @post_office = Queueing::PostOffice.new self
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

    class ServerConfiguration
      include ConfiguredByHash

      attr_config :background, :pidfile, :working_directory, :environment
    end

  end

  class ValueHolder
    attr_reader :values
    private     :values

    def initialize
      @values = {}
    end

    def to_h
      values.dup
    end

    def method_missing(method_id, *args)
      method_name = method_id.to_s
      return __send__(method_name[0...-1].to_sym, *args) if method_name[-1] == '='

      if block_given?
        value_holder = self.class.new
        yield(value_holder)
        return values[method_id] = value_holder.to_h
      end

      if method_name.start_with? 'add_'
        attr = method_name[4..-1].to_sym
        if value[attr]
          case value[attr]
            when Array
              raise ArgumentError, "The treatment of attribute #{attr} is confused" if args.count != 1
              value[attr] << args.shift
            when Hash
              raise ArgumentError, "The treatment of attribute #{attr} is confused" if args.count != 2
              value[attr][args[0].to_sym] = args[1]
            else
              raise "#{attr} is already defined as scalar even if it would be added"
          end
          return value[attr]
        else
          case args.count
            when 1
              value[attr] = [args.shift]
            when 2
              value[attr] = {args[0].to_sym => args[1]}
            else
              raise ArgumentError, "#{method_id} should be called with 1 or 2 argument(s)."
          end
        end
        return value[attr]
      end

      return values[method_id] = args.shift if args.size > 0

      return values[method_id]
    end
  end

  class TopLevelValueHolder < ValueHolder
    def queue(name)
      raise ArgumentError, 'queue must be accompanied with block' unless block_given?
      queue_value_holder = ValueHolder.new
      yield(queue_value_holder)

      values[:queues] ||= {}
      values[:queues][name.to_sym] = queue_value_holder.to_h
    end
  end

  class MisconfigurationError < StandardError;end
end
