module Arsenicum
  module Queueing
    class PostOffice
      include Serializer

      attr_reader :queues
      attr_reader :default_queue
      attr_reader :method_queue_tables
      attr_reader :class_queue_tables

      def initialize(configuration)
        @method_queue_tables = {}
        @class_queue_tables = {}

        @queues = configuration.queue_configurations.inject({}) do |h, kv|
          (queue_name, queue_configuration) = kv
          queue = configuration.queue_class.new(
              queue_name,
              logger: configuration.logger,
              config: queue_configuration,
              engine_config: configuration.engine_configuration
          )

          Array(queue_configuration.methods).tap(&:compact!).each do |m|
            method_queue_tables[m] ||= queue
          end
          Array(queue_configuration.classes).tap(&:compact!).each do |m|
            class_queue_tables[m] ||= queue
          end
          h[queue_name] = queue

          h
        end
        @default_queue = queues[:default]
      end

      def post(request)
        specify_queue(request.target, request.method_name).put(request.serialize)
      end

      def logger
        configuration.logger
      end

      private
      def specify_queue(target, method)
        if target.is_a?(Module)
          conjunction = '.'
          klass = target
        else
          conjunction = '#'
          klass = target.class
        end
        method_signature = [klass.name, method].join conjunction
        if queue = method_queue_tables[method_signature]
          return queue
        end
        klass_signature = klass.name
        if queue = class_queue_tables[klass_signature]
          return queue
        end

        return default_queue
      end
    end
  end
end
