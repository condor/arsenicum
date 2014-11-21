class Arsenicum::Core::Broker
  include Arsenicum::Core::IOHelper

  attr_reader   :router

  attr_reader   :workers,       :available_workers, :mutex
  attr_reader   :worker_count,  :worker_options,    :tasks
  attr_accessor :default_task

  PROCESSOR_COUNT_DEFAULT = 2

  def initialize(options = {})
    @worker_count = (options.delete(:worker_count) || PROCESSOR_COUNT_DEFAULT).to_i
    @mutex = Mutex.new
    @tasks = {}
    @router = options.delete :router

    serializer = options[:serializer]  ||  Arsenicum::Serializer::JSON.new
    formatter  = options[:formatter]   ||  Arsenicum::Formatter.new
    @worker_options = options.delete(:worker_options) || {}
    @worker_options.merge! serializer: serializer,  formatter: formatter
  end

  def [](task_id)
    tasks[task_id.to_sym] || default_task
  end

  def []=(task_id, task)
    tasks[task_id.to_sym] = task
  end

  alias_method :register, :[]=

  def run
    @workers = {}
    @available_workers = {}

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
    workers.values.map(&:stop)
  end

  def remove(worker)
    mutex.synchronize do
      workers.delete(worker.pid)
      available_workers.delete(worker.pid)
    end
  end

  def reload
    workers.values.each(&:stop)

    workers.clear
    available_workers.clear

    prepare_workers
  end

  def get_back_worker(worker)
    mutex.synchronize{
      if worker.active?
        available_workers[worker.pid] = worker
      else
        next_index = workers.count
        remove worker
        worker.stop
        prepare_worker next_index
      end
    }
  end

  private
  def prepare_workers
    @worker_count.times do |i|
      prepare_worker i
    end
  end

  def prepare_worker index
    worker = Arsenicum::Core::Worker.new(self, index, worker_options)
    stock(worker)
  end

  def stock(worker)
    mutex.synchronize do
      pid = worker.run
      workers[pid] = worker
      available_workers[pid] = worker
    end
  end

  def next_worker
    mutex.synchronize do
      (_, worker) = available_workers.shift
      worker
    end
  end

  def serialize(value = {})
    serializer.serialize value
  end
end
