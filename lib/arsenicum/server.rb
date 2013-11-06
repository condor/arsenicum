module Arsenicum
  module Server
    DEFAULT_QUEUES = {
      default: {
        concurrency: 1,
      },
    }.freeze

    class << self
      attr_reader :watchdogs
    end

    def self.start(settings = {})
      config = Arsenicum::Configuration.new({queues: DEFAULT_QUEUES}.merge(settings || {}))
      queue_class = config.queue_class
      @watchdogs = config.queue_configurations.map do |queue_name, queue_config|
        queue = queue_class.new(config.engine_configuration.merge(queue_config))
        Arsenicum::WatchDog.new(queue)
      end
      watchdogs.each{|dog|dog.async.boot}
    end

    def self.shutdown
      @watchdogs.each(&:terminate)
    end
  end
end
