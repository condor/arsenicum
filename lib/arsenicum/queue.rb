require 'weakref'

class Arsenicum::Queue
  include Celluloid
  attr_reader :worker_pool, :name

  def initialize(configuration)
    @name         = configuration.name
    @worker_pool  = Arsenicum::Worker.pool(size: configuration.worker.count, args: self)
  end

  def start
    Arsenicum::Logger.info{"[queue]Queue #{name} is now starting"}
    broker.run
    Arsenicum::Logger.info{"[queue]Queue #{name} start-up completed"}

    boot
  end

  def feed(task)
    worker_pool.async.request task, method(:handle_success), method(:handle_failure)
  end

  def stop
    broker.stop
  end

  def register(task)
    broker[task.id] = task
  end

  def handle_success(original_message)
    #TODO implement correctly in your derived classes.
  end

  def handle_failure(e, original_message)
    #TODO implement correctly in your derived classes.
  end

  private
  def build_router(router_class)
    return unless router_class
    router_class.new self
  end

  autoload  :Sqs, 'arsenicum/queue/sqs'
end
