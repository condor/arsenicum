require 'timeout'
require 'forwardable'
require 'weakref'

module Arsenicum
  module Processing
    class Processor
      attr_reader :waiting_tasks, :concurrency, :current_concurrency, :queue, :logger

      def initialize(queue)
        @mutex = Mutex.new
        @watchdogs_mutex = Mutex.new
        @queue = queue
        @concurrency = queue.concurrency
        @logger = queue.logger
        @current_concurrency = 0

        @workers = concurrency.times.map {|_| Worker.new self }
        @waiting_tasks = Array.new(concurrency)
        @watchdogs = concurrency.times.map{|_| WatchDog.new queue.timeout}

        Thread.new do
          loop do
            (worker, task) = @mutex.synchronize do
              next unless task = @waiting_tasks.shift
              [@workers.shift, task]
            end
            worker ? worker.start_with(task) : sleep(0.1)
          end
        end
      end

      def boot
        @main_thread = Thread.new do
          begin
            loop do
              retrieved = @mutex.synchronize do
                next if full?

                begin
                  next unless message = queue.receive
                rescue Exception => e
                  logger.info e
                  next
                end

                begin
                  watchdog = @watchdogs_mutex.synchronize{@watchdogs.shift}
                  watchdog.start(target: Thread.current)
                  request = Arsenicum::Queueing::Request.restore(message[:body], message[:id], queue.raw?)
                  task = Task.new(request, watchdog)
                  push(task)
                  true
                rescue Exception => e
                  logger.error "Message corrupts: message was #{message.inspect}"
                  next
                end
              end

              wait if retrieved
            end
          rescue Exception => e
            logger.error e
            raise
          end
        end
        self
      end

      def accept_replacement(worker: nil)
        @mutex.synchronize do
          @workers.push(worker)
          @current_concurrency -= 1
        end
      end

      private
      def push(request)
        waiting_tasks << request
        @current_concurrency += 1
      end

      def full?
        current_concurrency == concurrency
      end

      def complete
        @mutex.synchronize{@current_concurrency -= 1}
      end

      def synchronize
        return unless block_given?
        @mutex.synchronize{yield}
      end

      def wait
        sleep 0.1
      end

      def shutdown
        @main_thread.terminate
        @workers.each do |worker|
          worker.thread.terminate
        end
      end

      class Task
        attr_reader :request

        def initialize(queue, request, watchdog = nil)
          @request = request
          @watchdog = watchdog
        end

        def switch_context
          @watchdog.switch_context if @watchdog
        end

        def complete
          @watchdog.stop if @watchdog
        end
      end

      class WatchDog
        def initialize(timeout)
          @thread = Thread.new do
            loop do
              @context.raise(Timeout::Error) if @start && Time.now.to_f - @start > timeout
              next sleep(0.01)
            end
          end
        end

        def start
          @context = Thread.current
          @start = Time.now.to_f
        end

        def stop
          @start = nil
          @context = nil
        end

        def switch_context
          @context = Thread.current
        end
      end


      class Worker
        extend Forwardable

        attr_reader   :thread, :request
        def_delegator :queue,   :@processor


        def initialize(processor)
          @processor = WeakRef.new(processor)
          @mutex = Mutex.new

          @thread = Thread.new do
            loop do
              # Avoid termination even if Timeout::Error is raised.
              begin
                next(sleep 0.5) unless task
              rescue Timeout::Error
                next
              end

              begin
                task.switch_context
                work
              rescue Exception => e
                task.handle_error e
              ensure
                complete_work
              end
            end
          end
        end

        def complete_work
          task.complete
          @mutex.synchronize do
            processor.complete
            @processor.accept_replacement worker: self
            @task = nil
          end
        end

        def run
          work.run
          work.handle_success
        end

        def interrupt
          @mutex.synchronize do
            return unless task
            @thread.raise Timeout::Error
          end
        end

        def start_with(task)
          @task = task
        end
      end
    end
  end
end
