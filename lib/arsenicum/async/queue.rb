class Arsenicum::Async::Queue < Arsenicum::Core::Broker

  attr_accessor :broker
  attr_reader   :name,  :worker_count,  :router
  attr_reader   :broker

  def initialize(name, options)
    @name = name
    @worker_count = options.delete(:worker_count)
    @router       = options.delete(:router)
    @broker       = Arsenicum::Core::Broker.new worker_count: worker_count, router: router
  end

  def start
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

  def register_task(task)
    broker[task.id] = task
  end

  def start_async
    Thread.new{start}
  end

  autoload  :Sqs, 'arsenicum/async/queue/sqs'
end
