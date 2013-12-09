module Arsenicum
  module Queueing
    class PostOffice
      include Serializer

      attr_reader :queues
      attr_reader :default_queue
      attr_reader :method_queue_tables
      attr_reader :class_queue_tables

      def initialize(configuration)
        queue_class = configuration.queue_class
        @method_queue_tables = {}
        @class_queue_tables = {}

        @queues = configuration.queue_configurations.inject({}) do |h, kv|
          (queue_name, queue_configuration) = kv
          queue = queue_class.new(
              queue_name,
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

      def deliver_to(target, method, *arguments)
        values = {
            target: {
                target: serialize_object(target),
                timestamp: (Time.now.to_f * 1000000).to_i,
                method_name: method_name,
                arguments: arguments.nil? ? nil : arguments.map { |arg| serialize_object(arg) },
            },
            method_name: method,
            arguments: arguments.map{|arg|{
                target: serialize_object(target),
                timestamp: (Time.now.to_f * 1000000).to_i,
                method_name: method_name,
                arguments: arguments.nil? ? nil : arguments.map { |arg| serialize_object(arg) },
            }
            },
        }
        specify_queue(target, method).
            tap{|q|logger.debug { "Queue #{q.name}: Param #{values.inspect}" }}.
            put(values)
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
        klass_signature = target.class.name
        if queue = class_queue_tables[klass_signature]
          return queue
        end

        return default_queue
      end
    end
  end
end
