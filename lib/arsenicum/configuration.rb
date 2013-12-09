require 'logger'

module Arsenicum
  class Configuration
    attr_accessor :queue_namespace, :queue_type, :queue_configurations, :engine_configuration,
                  :pidfile, :background, :log_level, :post_office
    attr_reader :logger

    DEFAULT_QUEUES = {
      default: {
        concurrency: 2,
      },
    }.freeze

    class << self
      def configure(configuration)
        @instance = new(configuration)
      end
      attr_reader :instance

      def reconfigure(settings)
        instance.reconfigure additional_settings: settings
      end
    end

    def initialize(settings)
      @log_level = Logger::INFO
      @logger = Logger.new(STDOUT)

      @original_settings = {queues: DEFAULT_QUEUES}.merge(normalize_hash_key(settings))
      raise MisconfigurationError, "queue_type is required" unless @original_settings[:queue_type]

      reconfigure
    end

    def reconfigure(additional_settings: nil)
      @original_settings.merge! additional_settings if additional_settings
      settings = @original_settings.dup

      @pidfile = settings.delete(:pidfile)
      @background = (settings.delete(:background).to_s.downcase == "true")
      @queue_type = settings.delete(:queue_type).to_s
      @engine_configuration = settings[queue_type.to_sym]
      @queue_namespace = queue_type.gsub(/_([a-z])/){|_|$1.upcase}.gsub(/^([a-z])/){|_|$1.upcase}.to_sym

      queue_settings = settings.delete(:queues)
      @queue_configurations = queue_settings.inject({}) do |h, kv|
        (queue_name, queue_setting) = kv
        h[queue_name] = queue_setting
        h
      end

      if log_level = settings.delete(:log_level)
        @log_level = Logger.const_get(log_level.upcase.to_sym)
      end

      if log_file = settings.delete(:log_file)
        self.logger = Logger.new(log_file)
      end

      @post_office = Arsenicum::Queueing::PostOffice.new(self)
    end

    def logger=(new_logger)
      @logger = new_logger
      if @logger
        @logger.level = log_level
      end
    end

    def create_queues
      queue_configurations.map do |queue_name_config|
        (queue_name, queue_config) = queue_name_config
        queue_class.new(queue_name, engine_configuration.merge(queue_config), logger)
      end
    end

    def queue_class
      Arsenicum.const_get(queue_namespace).const_get(:Queue)
    end

    private
    def normalize_hash_key(hash, to_sym: true)
      hash.inject({}) do |h, kv|
        (key, value) = kv
        value = normalize_hash_key(value, to_sym: to_sym) if value.is_a? Hash
        key = to_sym ? key.to_sym : key.to_s
        h[key] = value
        h
      end
    end
  end

  class MisconfigurationError < StandardError;end
end
