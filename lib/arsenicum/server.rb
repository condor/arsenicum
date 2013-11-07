module Arsenicum
  module Server
    class << self
      attr_reader :watchdogs
    end

    def self.start(config = Arsenicum::Configuration.instance)
      queue_class = config.queue_class
      @watchdogs = config.create_queues.map do |queue|
        Arsenicum::WatchDog.new(queue)
      end

      waiter_thread = Thread.new { loop { sleep 10 } }
      begin
        waiter_thread.join
      rescue Interrupt
        shutdown
      end
    end

    def self.shutdown
      @watchdogs.each(&:shutdown)
    end
  end
end
