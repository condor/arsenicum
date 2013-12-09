require 'timeout'

module Arsenicum
  module Processing
    class QueuePicker
      attr_reader :queue, :logger, :processor

      def initialize(queue, logger)
        @queue = queue
        @logger = logger
        @processor = Arsenicum::Processing::Processor.new queue
      end

      def boot
        @main_thread = Thread.new do
          loop do
            message = queue.poll
            next unless message

            request = Arsenicum::Queueing::Request.restore(message[:body], message[:id])
            processor.push(request)
          end
        end
      end

      def shutdown
        @processor.terminate
        @main_thread.terminate
      end
    end
  end
end
