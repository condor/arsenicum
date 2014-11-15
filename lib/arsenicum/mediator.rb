class Arsenicum::Mediator
  attr_reader :workers,  :available_workers

  attr_reader :worker_count, :worker_options, :serializer

  PROCESSOR_COUNT_DEFAULT = 2

  def initialize(options)
    @worker_count = (options.delete(:worker_count) || PROCESSOR_COUNT_DEFAULT).to_i
    @worker_options = options.delete(:worker_options) || {}
    @serializer = options[:serializer] || Arsenicum::Serializer::JSON.new
  end

  def run
    @workers = {}
    @available_workers = []

    @worker_count.times do
      processor = Arsenicum::Worker.new(worker_options.merge(serializer: serializer))
      pid = processor.run
      workers[pid] = processor
      available_workers << workers
    end
  end

  def accept(task)
    until (worker = available_workers.shift)
      sleep 0.5
    end

    begin
      worker.preprocess
      worker.ask serialize(task)
      worker.postprocess
    ensure
      available_workers << worker if worker.active?
    end
  end

  def serialize(value)
    serializer.serialize value
  end
end