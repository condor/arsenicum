require 'fileutils'

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
        if config.server.pidfile
          dirname = File.dirname(config.server.pidfile)
          FileUtils.mkpath dirname unless Dir.exist? dirname
          File.open(config.server.pidfile, 'w'){|f|f.puts $$}
        end
        new(config).start
      end

      def start
        config.logger.info "Booting Arsenicum Processor..."
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
        puts "Shutting down Arsenicum Processor..."

        @queue_pickers.each(&:shutdown)
        File.delete config.server.pidfile if config.server.pidfile && File.exist?(config.server.pidfile)
        puts "Shutting down completed"
        Thread.current.terminate
      end

      private
      def trap_interruption(*)
        shutdown
      end
    end
  end
end
