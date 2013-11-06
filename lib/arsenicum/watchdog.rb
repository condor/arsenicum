module Arsenicum
  class WatchDog
    include Celluloid

    attr_reader :queue, :pool

    def initialize(queue)
      @queue = queue
      @pool = Arsenicum::Actor.pool size: queue.concurrency, args: queue
    end

    def boot
      loop do
        message = queue.poll
        next unless message

        task = Task.parse(message[:message_body], message[:message_id])
        pool.async.process task
      end
    end
  end
end
