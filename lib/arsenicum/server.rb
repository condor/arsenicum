module Arsenicum
  class Server
    attr_reader :watchdogs
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def self.start(config = Arsenicum::Configuration.instance)
      if config.pidfile
        File.open(config.pidfile){|f|f.puts $$}
      end

      if config.background
        fork do
          new(config).start
        end
        exit
      end
    end

    def start
      puts "Booting Arsenicum Server..."
      Signal.trap(:INT, &method(:trap_interruption))

      queue_class = config.queue_class
      @watchdogs = config.create_queues.map do |queue|
        Arsenicum::WatchDog.new(queue)
      end

      loop { sleep 10 }
    end

    def shutdown
      @watchdogs.each(&:shutdown)
      Thread.current.terminate
      File.delete config.pidfile if config.pidfile
    end

    private
    def trap_interruption(*)
      shutdown
    end
  end
end
