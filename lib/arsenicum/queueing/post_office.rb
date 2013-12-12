module Arsenicum
  module Queueing
    class PostOffice
      include Serializer

      attr_reader :queues
      attr_reader :default_queue
      attr_reader :method_queue_tables
      attr_reader :class_queue_tables

      def initialize(config)
        @method_queue_tables = {}
        @class_queue_tables = {}

        @queues = config.queue_configs.values.inject({}) do |h, queue_config|
          queue = config.queue_class.new(
              queue_config,
              logger: config.logger,
              engine_config: config.engine_config
          )

          Array(queue_config.methods).tap(&:compact!).each do |m|
            method_queue_tables[m] ||= queue
          end
          Array(queue_config.classes).tap(&:compact!).each do |m|
            class_queue_tables[m] ||= queue
          end
          h[queue.name] = queue

          h
        end
        @default_queue = queues[:default]
      end

      def post(request)
        specify_queue(request.target, request.method_name).put(request.serialize)
      end

      def logger
        config.logger
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
