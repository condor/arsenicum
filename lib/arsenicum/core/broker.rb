class Arsenicum::Core::Broker
  include Arsenicum::Core::IOHelper

  attr_reader   :router

  attr_reader   :workers,       :available_workers, :mutex
  attr_reader   :worker_count,  :worker_options,    :tasks
  attr_accessor :default_task

  PROCESSOR_COUNT_DEFAULT = 2

  def initialize(options = {})
    @worker_count = (options.delete(:worker_count) || PROCESSOR_COUNT_DEFAULT).to_i
    @tasks = {}
    @router = options.delete :router

    serializer = options[:serializer]  ||  Arsenicum::Serializer::JSON.new
    formatter  = options[:formatter]   ||  Arsenicum::Formatter.new
    @worker_options = options.delete(:worker_options) || {}
    @worker_options.merge! serializer: serializer,  formatter: formatter
    @current_worker_index = -1 # because it is incremented whenever used. (primary index should be ZERO)
    @mutex = Mutex.new
  end

  def [](task_id)
    tasks[task_id.to_sym] || default_task
  end

  def []=(task_id, task)
    tasks[task_id.to_sym] = task
  end

  alias_method :register, :[]=

  def run
    @workers = []
    @available_workers = []

    prepare_workers
  end

  def broker(success_handler, failure_handler, task_id, *parameters)
    worker = loop do
      w = next_worker
      break w if w

      sleep 0.5
    end

    Arsenicum::Logger.info { "[broker][Task brokering]id=#{task_id}, params=#{parameters.inspect}" }
    worker.ask_async success_handler, failure_handler, task_id, *parameters
  end

  def delegate(message, success_handler, failure_handler)
    (task_id, parameters) = router.route(message)
    broker success_handler, failure_handler, task_id, parameters
  end

  def stop
    workers.each(&:stop)
  end

  def remove(worker)
    available_workers.delete(worker)
    workers.delete(worker)
  end

  def reload
    stop

    available_workers.clear
    workers.clear

    prepare_workers
  end

  def get_back_worker(worker)
    if worker.active?
      available_workers << worker
    else
      remove worker
      worker.stop
      prepare_worker
    end
  end

  private
  def prepare_workers
    @worker_count.times{prepare_worker}
  end

  def prepare_worker
    worker = Arsenicum::Core::Worker.new(self, next_worker_index, worker_options)
    stock(worker)
  end

  def next_worker_index
    mutex.synchronize{
      @current_worker_index += 1
    }
  end

  def stock(worker)
    workers << worker
    available_workers << worker
  end

  def next_worker
    mutex.synchronize{available_workers.shift}
  end

  def serialize(value = {})
    serializer.serialize value
  end
end
