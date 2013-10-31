module Arsenicum
  class QueueProxy
    include Serialization

    class <<self
      attr_accessor :default
    end

    attr_reader :configuration
    attr_reader :queues
    attr_reader :default_queue
    attr_reader :method_queue_tables
    attr_reader :class_queue_tables

    def initialize(configuration)
      @configuration = configuration
      queue_class = configuration.queue_class
      @method_queue_tables = {}
      @class_queue_tables = {}

      @queues = configuration.queue_configurations.inject({}) do |h, kv|
        (queue_name, queue_configuration) = kv
        queue = queue_class.new(queue_configuration.merge(configuration.engine_coniguration))
        Array(queue.queue_methods).tap(&compact!).each do |m|
          method_queue_tables[m] ||= queue
        end
        Array(queue.queue_classes).tap(&compact!).each do |m|
          class_queue_tables[m] ||= queue
        end

        h
      end
      @default_queue = queues['default']
    end

    def async(target, method, *arguments)
      values = {
        target: prepare_serialization(target),
        method_name: method,
        arguments: arguments.map{|arg|prepare_serialization(arg)},
      }
      specify_queue(target, method).put(values)
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
      method_signature = [target.class.name, method].join conjunction
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
