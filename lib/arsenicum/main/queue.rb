class Arsenicum::Main::Queue < Arsenicum::Main
  attr_config_reader  :queue_name,  :queue_class
  attr_reader :queue

  def process_name
    "arsenicum_queue[#{queue_name}]"
  end

  def boot
    @queue = queue_class.new config
    @queue.start
  end
end
