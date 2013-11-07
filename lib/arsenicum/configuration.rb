module Arsenicum
  class Configuration
    attr_accessor :queue_namespace, :queue_type, :queue_configurations, :engine_configuration

    def initialize(settings)
      settings = normalize_hash_key(settings)
      raise MisconfigurationError, "queue_type is required" unless settings[:queue_type]

      @queue_type = settings[:queue_type].to_s
      @engine_configuration = settings[queue_type.to_sym]
      @queue_namespace = queue_type.gsub(/_([a-z])/){|_|$1.upcase}.gsub(/^([a-z])/){|_|$1.upcase}.to_sym

      queue_settings = settings.delete(:queues)
      @queue_configurations = queue_settings.inject({}) do |h, kv|
        (queue_name, queue_setting) = kv
        h[queue_name] = queue_setting
        h
      end
    end

    def create_queues
      queue_configurations.map do |queue_name_config|
        (queue_name, queue_config) = queue_name_config
        queue_class.new(queue_name, engine_configuration.merge(queue_config))
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
