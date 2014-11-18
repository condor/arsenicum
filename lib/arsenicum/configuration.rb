require 'logger'

module Arsenicum
  class MisconfigurationError < StandardError;end

  class Configuration
    def queue_configurations
      @queue_configurations ||= []
    end

    def queue(name)
      queue_config = QueueConfiguration.new name
      yield queue_config if block_given?
      queue_configurations << queue_config
    end

    class QueueConfiguration
      include Arsenicum::Util

      attr_reader :name, :worker_count, :initialize_parameters

      def initialize(name)
        @name = name
        @worker_count = 2
      end

      def workers(count)
        @worker_count = count
      end

      def type(type_name)
        @queue_class = constantize(classify(type_name))
      rescue NameError
        @queue_class = constantize(classify(type_name), inside: Arsenicum::Async::Queue)
      end

      def build_queue

      end
    end

    class ConfigurationHash < Hash
      def in_configuration?
        @in_configuration
      end

      def under_configuration(&_)
        @in_configuration = true
        yield if block_given?
      ensure
        @in_configuration = false
      end

      def method_missing(method_id, *args)
        case args.length
          when 0
            return self[method_id] unless in_configuration?

            if block_given?
              new_value = ConfigurationHash.new
              yield new_value
              self[method_id] = new_value
            else
              self[method_id] ||= ConfigurationHash.new
            end
          when 1
            if (method_name = method_id.to_s)[-1] == '='
              return self[method_name[0...-1].to_sym] = args.first
            end

            self[method_id] = args.first
          else
            super
        end
      end
    end
  end
end
