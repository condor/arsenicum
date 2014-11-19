class Arsenicum::Queue

  attr_accessor :broker
  attr_reader   :name,  :worker_count,  :router
  attr_reader   :broker

  def initialize(name, options)
    @name         = name
    @worker_count = options.delete(:worker_count)
    @router       = build_router options.delete(:router_class)
    @broker       = Arsenicum::Core::Broker.new worker_count: worker_count, router: router
  end

  def start
    broker.run

    loop do
      (message, success_handler, failure_handler) = pick
      next sleep(0.5) unless message

      begin
        broker.delegate message
        success_handler.call if success_handler
      rescue Exception => e
        failure_handler.call(e) if failure_handler
      end
    end
  end

  def register(task)
    broker[task.id] = task
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
