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
          begin
            loop do
              retrieved = processor.synchronize do
                next if processor.full?
                begin
                  next unless message = queue.receive
                rescue Exception => e
                  logger.info e
                  next
                end

                logger.debug{"Message picked up #{message.inspect}"}

                begin
                  request = Arsenicum::Queueing::Request.restore(message[:body], message[:id])
                  processor.push(request)
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
