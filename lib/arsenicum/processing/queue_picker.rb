require 'timeout'

module Arsenicum
  module Processing
    class QueuePicker
      attr_reader :queue, :logger, :processor

      def initialize(queue)
        @queue = queue
        @logger = queue.logger
        @processor = Arsenicum::Processing::Processor.new queue
      end

      def boot
        @main_thread = Thread.new do
          loop do
            processor.synchronize do
              next wait if processor.full?
              next wait unless message = queue.poll

              processor.push(Arsenicum::Queueing::Request.restore(message[:body], message[:id]))
            end

          end
        end
      end

      def wait
        sleep 0.1
      end

      def shutdown
        @processor.terminate
        @main_thread.terminate
      end
    end
  end
end
