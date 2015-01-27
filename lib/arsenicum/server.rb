class Arsenicum::Server
  attr_reader :configurations, :queues

  def initialize(configurations)
    @configurations = configurations

    @queues = configurations.queues.inject({}) do |h, (queue_name, queue_config)|
      queue_name = queue_name.to_sym
      h.merge! queue_name => queue_class.new(queue_name, queue_config)
    end
  end

  def start
    wait_queues
  end

  def post(queue_name, message)
    queues[queue_name.to_sym].post message
  end

  # derived classes must implement wait_queues and queue_class.
end
