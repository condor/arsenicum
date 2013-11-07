require 'json'

module Arsenicum
  class Queue
    DEFAULT_CONCURRENCY = 5

    attr_reader :name, :concurrency, :queue_methods, :queue_classes

    def initialize(name, config = {})
      @name = name
      @concurrency = (config.delete(:concurrency) || DEFAULT_CONCURRENCY).to_i
      @queue_methods = config.delete(:methods)
      @queue_classes = config.delete(:classes)
      configure(config)
    end

    def put(hash)
      json = JSON(hash.merge(timestamp: Time.to_f.to_s.tap{|t|t.sub! '.', ''}))
      put_to_queue(json)
    end

    ######################################################
    #
    # Queue must implement the methods as below:
    #   1. put_to_queue(json): putting the actual message
    #     into the queue backend. The argument of this
    #     method will be the JSON string.
    #   2. poll: polling the queue and retrieve the
    #     message information. This method is expected to
    #     return the message Hash. Its keys and values
    #     are expected as below:
    #       :message_body: the raw string that was pushed
    #         via the :put_to_queue method.
    #       :message_id: the identifier of this message.
    #         This is usually used to update the status of
    #         message on the queue backend.
    #   3. update_message_status(message_id, successful):
    #     Update the status of the message. Arguments are
    #     as following:
    #       message_id: The identifier of the message to
    #         be updated. This value will be set as the
    #         :message_id of the return value of :poll.
    #       successful: The result of the process done.
    #         If the process complete successfully,
    #         this argument will be set true. Otherwise,
    #         this will be false.
    #####################################################
  end
end
