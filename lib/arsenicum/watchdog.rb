module Arsenicum
  class WatchDog
    attr_reader :queue

    def initialize(queue)
      @queue = queue

      @task_queue = Array.new
      @mutex = Mutex.new
      @workers = queue.concurrency.times.map{|_|create_worker}
    end

    def boot
      @main_thread = Thread.new do
        loop do
          message = queue.poll
          next unless message

          @mutex.synchronize do
            @task_queue.push Task.parse(message[:message_body], message[:message_id])
          end
        end
      end
    end

    def join
      @main_thread.join
    end

    private
    def create_worker
      Worker.new
    end

    class Worker < ::Thread
      def initialize(task_queue, queue)
        super do
          loop do
            task = task_queue.shift
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
