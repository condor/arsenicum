module Arsenicum
  class Server
    autoload :WatchDog, 'arsenicum/server/watchdog'
    autoload :Actor, 'arsenicum/server/actor'

    attr_reader :watchdogs
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def self.start(config = Arsenicum::Configuration.instance)
      Process.daemon(true, true) if config.background
      File.open(config.pidfile, 'w'){|f|f.puts $$} if config.pidfile
      new(config).start
    end

    def start
      puts "Booting Arsenicum Server..."
      Signal.trap(:INT, &method(:trap_interruption))

      queue_class = config.queue_class
      @watchdogs = config.create_queues.map do |queue|
        Arsenicum::WatchDog.new(queue, config.logger)
      end
      @watchdogs.each(&:boot)

      loop { sleep 10 }
    end

    def shutdown
      @watchdogs.each(&:shutdown)
      File.delete config.pidfile if config.pidfile
      Thread.current.terminate
    end

    private
    def trap_interruption(*)
      shutdown
    end
  end
end
