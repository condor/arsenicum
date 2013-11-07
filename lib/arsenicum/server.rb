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
      watchdogs.each{|dog|dog.async.boot}

      watchdogs.each{|dog|dog.future.value}
    end

    def self.shutdown
      @watchdogs.each(&:terminate)
    end
  end
end
