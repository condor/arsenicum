module Arsenicum
  module Server
    DEFAULT_QUEUES = {
      default: {
        concurrency: 2,
      },
    }.freeze

    class << self
      attr_reader :watchdogs
    end

    def self.start(config = Arsenicum::Configuration.instance)
      queue_class = config.queue_class
      @watchdogs = config.create_queues.map do |queue|
        Arsenicum::WatchDog.new(queue)
      end
      watchdogs.each{|dog|dog.async.boot}
    end

    def self.shutdown
      @watchdogs.each(&:terminate)
    end
  end
end
