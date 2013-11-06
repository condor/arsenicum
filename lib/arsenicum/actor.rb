require 'celluloid'

module Arsenicum
  class Actor
    include Celluloid

    attr_reader :queue

    def initialize(queue)
      @queue = queue
    end

    def process(task)
      task.execute
      queue.update_message_status(task.message_id, task.successful?)
    end
  end
end
