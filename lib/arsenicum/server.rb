module Arsenicum
  module Server
    DEFAULT_QUEUES = {
      default: {
        concurrency: 1,
      },
    }.freeze

    def self.start(settings = {})
      config = Arsenicum::Configuration.new({queues: DEFAULT_QUEUES}.merge(settings || {}))
      queue_class = configuration.queue_class
      config.queue_configurations.each do |queue_name, queue_config|
        queue = queue_class.new(queue_config)
        Arsenicum::WatchDog.new(queue).boot
      end
    end

    def self.shutdown
    end
  end
end
