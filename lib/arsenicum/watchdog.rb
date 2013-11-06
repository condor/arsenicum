module Arsenicum
  class WatchDog
    attr_reader :queue, :pool

    def initialize(queue)
      @queue = queue
    end

    def boot
      @pool = Arsenicum::Actor.pool size: queue.concurrency, args: queue

      loop do
        message = queue.poll
        next unless message

        task = Task.parse(message[:message_body], message[:message_id])
        pool.async.process task
      end
    end
  end
end
