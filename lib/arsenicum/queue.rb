require 'weakref'

class Arsenicum::Queue

  attr_reader   :name,  :worker_count,  :router
  attr_reader   :broker

  def initialize(name, options)
    @name         = name
    @worker_count = options.delete(:worker_count)
    @router       = build_router options.delete(:router_class)
    @broker       = Arsenicum::Core::Broker.new worker_count: worker_count, router: router
  end

  def start
    Arsenicum::Logger.info{"[queue]Queue #{name} is now starting"}
    broker.run
    Arsenicum::Logger.info{"[queue]Queue #{name} start-up completed"}

    loop do
      begin
        (message, original_message) = pick
      rescue => e
        handle_failure e, original_message
        next
      end

      unless message
        sleep(0.5)
        next
      end

      Arsenicum::Logger.info{"Queue picked. message: #{message.inspect}"}
      broker.delegate message, -> { handle_success(original_message) }, -> e { handle_failure(e, original_message) }
    end
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

  def start_async
    Thread.new{start}
  end

  private
  def build_router(router_class)
    return unless router_class
    router_class.new self
  end

  autoload  :Sqs, 'arsenicum/queue/sqs'
end
