require 'timeout'
require 'forwardable'

module Arsenicum
  module Processing
    class Processor
      attr_reader :head, :tail, :max_size , :current_size

      def initialize(queue, options = {})
        @mutex = Mutex.new
        @queue = queue
        @max_size = options[:workers].to_i
        @current_size = 0

        @workers = @max_size.times.map do |_|
          Worker.new self
        end

        Thread.new do
          loop do
            next(sleep 1) unless work = pickup
            @workers.shift.work_with work
          end
        end
      end

      def push(request)
        return if current_size == max_size

        @mutex.synchronize do
          return if current_size == max_size

          work = Work.new queue, request
          if tail
            tail.next = work
            work.prev = tail
          else
            @tail = work
          end

          @current_size += 1
        end
        true
      end

      def pickup
        @mutex.synchronize do
          item = head
          item = item.next while item && item.running?
          item
        end
      end

      def complete(work)
        work.synchronize do
          work.worker = nil
          work.mark_processed
        end

        @mutex.synchronize do
          if work == head
            @head = work.next
            head.prev = nil if head
          end

          if work == tail
            @tail = work.prev
            tail.next = nil if tail
          end

          @current_size -= 1
        end
      end

      def turn_in(worker: nil)
        @workers.push(worker)
      end

      def terminate
        @workers.each do |worker|
          worker.thread.terminate
        end
      end

      class Work
        include Forwardable

        attr_reader   :queue, :request
        attr_reader   :worker
        attr_reader   :next, :prev

        def_delegators :@mutex, :synchronize

        def initialize(queue, request)
          @request = request
          @queue = queue
          @mutex = Mutex.new

          if timeout = queue.configuration.detention_limit
            Thread.new do
              begin
                Timeout.timeout timeout do
                  loop do
                    break if processed?
                    sleep 1
                  end
                end
              rescue Timeout::Error => e
                worker.raise_error e if worker
              end
            end
          end
        end

        def run
          request.execute!
        end

        def worker=(worker)
          @worker = WeakRef.new(worker)
        end

        def running?
          @state == :running
        end

        def processed?
          @state == :processed
        end

        def mark_running
          @state = :running
        end

        def mark_processed
          @state = :processed
        end

        def timed_out?
          !!@timed_out
        end

        def handle_error(e)
          queue.handle_failure(request.message_id, e, request.raw_message)
        end

        def handle_success
          queue.handle_success(request.message_id)
        end
      end

      class Worker
        attr_reader :thread, :work

        def initialize(processor)
          @processor = WeakRef.new(processor)
          @thread = Thread.new do
            loop do
              next(sleep 0.5) unless work

              begin
                work.run
              rescue Exception => e
                work.handle_error e
              ensure
                processor.complete(work)
                @processor.turn_in worker: self
              end
            end
          end
        end

        def work_with(work)
          work.mark_running
          work.worker = self
          @work = work
        end

        def raise_error(e)
          thread.raise e
        end
      end
    end
  end
end
