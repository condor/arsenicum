class Arsenicum::Core::Broker
  include Arsenicum::Core::IOHelper

  attr_reader :workers,     :available_workers, :mutex

  attr_reader :worker_count, :worker_options, :tasks

  PROCESSOR_COUNT_DEFAULT = 2

  def initialize(options = {})
    @worker_count = (options.delete(:worker_count) || PROCESSOR_COUNT_DEFAULT).to_i
    @mutex = Mutex.new
    @tasks = {}

    serializer = options[:serializer]  ||  Arsenicum::Serializer::JSON.new
    formatter  = options[:formatter]   ||  Arsenicum::Formatter.new
    @worker_options = options.delete(:worker_options) || {}
    @worker_options.merge! serializer: serializer,  formatter: formatter
  end

  def register_task(task_id, task)
    tasks[task_id.to_sym] = task
  end

  def [](task_id)
    tasks[task_id.to_sym]
  end

  def []=(task_id, task)
    tasks[task_id.to_sym] = task
  end

  def run
    @workers = {}
    @available_workers = {}

    @worker_count.times do
      prepare_worker
    end
  end

  def prepare_worker
    worker = Arsenicum::Core::Worker.new(self, worker_options)
    stock(worker)
  end

  def stock(worker)
    mutex.synchronize do
      pid = worker.run
      workers[pid] = worker
      available_workers[pid] = worker
    end
  end

  def broker(task_id, parameters)
    until (worker = next_worker)
      sleep 0.5
    end

    begin
      worker.preprocess
      worker.ask task_id, parameters
      worker.postprocess
    ensure
      if worker.active?
        get_back_worker(worker)
      else
        remove(worker)
        prepare_worker
      end
    end
  end

  def remove(worker)
    mutex.synchronize do
      workers.delete(worker.pid)
      available_workers.delete(worker.pid)
    end
  end

  def next_worker
    mutex.synchronize{available_workers.shift.last}
  end

  def get_back_worker(worker)
    mutex.synchronize{available_workers << worker}
  end

  def serialize(value = {})
    serializer.serialize value
  end
end