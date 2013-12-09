module Arsenicum
  module Processing
    class Server
      attr_reader :queue_pickers
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def self.start(config = Arsenicum::Configuration.instance)
        Process.daemon(true, true) if config.server.background
        File.open(config.pidfile, 'w'){|f|f.puts $$} if config.server.pidfile
        new(config).start
      end

      def start
        puts "Booting Arsenicum Server..."
        Signal.trap(:INT, &method(:trap_interruption))

        @queue_pickers = config.queue_configurations.map do |kv|
          (queue_name, queue_config) = kv
          queue = config.queue_class.new(
              queue_name,
              logger: config.logger,
              config: queue_config,
              engine_config: config.engine_configuration,
          )

          QueuePicker.new(queue)
        end
        @queue_pickers.each(&:boot)

        loop { sleep 10 }
      end

      def shutdown
        @queue_pickers.each(&:shutdown)
        File.delete config.server.pidfile if config.server.pidfile && File.exist?(config.server.pidfile)
        Thread.current.terminate
      end

      private
      def trap_interruption(*)
        shutdown
      end
    end
  end
end
