require 'logger'

module Arsenicum
  class MisconfigurationError < StandardError;end

  class Configuration
    attr_reader :pidfile_path,  :queue_configurations

    def initialize
      @pidfile_path = 'arsenicum.pid'
    end

    def queue_configurations
      @queue_configurations ||= []
    end

    def queue(name, &block)
      queue_config = QueueConfiguration.new name
      queue_config.instance_eval &block if block_given?
      queue_configurations << queue_config
    end

    def pidfile(path)
      @pidfile_path = path
    end

    class InstanceConfiguration
      include Arsenicum::Util

      attr_reader :name, :init_parameters, :klass

      class << self
        attr_reader :inside
        private
        def namespace(mod)
          @inside = mod
        end
      end

      def initialize(name)
        @name = name
      end

      def inside
        self.class.inside
      end

      def type(type_name)
        @klass = constantize(classify(type_name))
      rescue NameError
        @klass = constantize(classify(type_name), inside: inside)
      end

      def init_params(&block)
        params = ConfigurationHash.new
        if block
          params.under_configuration do
            params.instance_eval(&block)
          end
        end
        @init_parameters = params
      end

      def build
        klass.new(name, init_parameters)
      end
    end

    class QueueConfiguration < Arsenicum::Configuration::InstanceConfiguration
      attr_reader :worker_count,  :task_configurations
      namespace Arsenicum::Async::Queue

      def initialize(name)
        super(name)
        @worker_count = 2
      end

      def workers(count)
        @worker_count = count
      end

      def task_configurations
        @task_configurations ||= []
      end

      def task(name, &block)
        task_config = TaskConfiguration.new name
        task_config.instance_eval &block if block_given?
        task_configurations << task_config
      end

      def build
        super.tap do |queue|
          task_configurations.each do |task_config|
            queue.register task_config.build
          end
        end
      end
    end

    class TaskConfiguration  < Arsenicum::Configuration::InstanceConfiguration
      namespace Arsenicum::Task
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

      def method_missing(method_id, *args, &block)
        case args.length
          when 0
            return self[method_id] unless in_configuration?

            if block_given?
              new_value = ConfigurationHash.new
              new_value.under_configuration do
                new_value.instance_eval &block
              end
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
