module Arsenicum
  class WatchDog
    attr_reader :queue, :logger

    def initialize(queue, logger)
      @queue = queue
      @logger = logger

      @task_queue = Array.new
      @mutex = Mutex.new
      @workers = queue.concurrency.times.map{|_|create_worker}
    end

    def boot
      @main_thread = Thread.new do
        loop do
          message = queue.poll
          next unless message

          # FIXME: overtime queue stocking.
          @mutex.synchronize do
            @task_queue.push Task.parse(message[:message_body], message[:message_id])
          end
        end
      end
    end

    def shutdown
      @workers.each do |worker|
        begin
          worker.terminate
        rescue Exception
        end
      end
      begin
        @main_thread.terminate
      rescue Exception
      end
    end

    private
    def create_worker
      Worker.new(@task_queue, @queue, @mutex)
    end

    #:nodoc:
    class Worker < ::Thread
      attr_reader :running

      def initialize(task_queue, queue, mutex)
        super do
          loop do
            mutex.synchronize { task = task_queue.shift }

            unless task
              sleep 0.1
              next
            end

            task.execute!
            queue.update_message_status(task.message_id, task.successful?, task.serialize)
          end
        end
      end
    end
  end
end
