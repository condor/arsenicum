require 'json'

module Arsenicum
  class Queue
    DEFAULT_CONCURRENCY = 5

    attr_reader   :name, :concurrency, :logger, :config, :engine_config

    def initialize(config, logger: logger, engine_config: nil)
      @name = config.queue_name
      @logger = logger
      @config = config
      @engine_config = engine_config

      @concurrency = config.concurrency
      @logger = logger || Logger.new(STDOUT)
      configure(config, engine_config)
    end

    def put(json)
      logger.debug { "Queue Put[#{name}] values #{json}" }
      put_to_queue(json)
    end

    ######################################################
    #
    # Queue must implement the methods as below:
    #   1. put_to_queue(json): putting the actual message
    #     into the queue backend. The argument of this
    #     method will be the JSON string.
    #   2. receive: receiving the top of the queue messages only once.
    #      It must the hash with the keys and values as described below:
    #       :body: the raw string that was pushed
    #         via the :put_to_queue method.
    #       :id: the identifier of this message.
    #         This is usually used to update the status of
    #         message on the queue backend.
    #   3. handle_success(id):
    #     The post-success process. Arguments are as below:
    #       id: The identifier of the message processed.
    #   4. handle_failure(id, exception, raw_message):
    #     The process if the task finishes in failure.
    #     Arguments are:
    #       id: The identifier of the message that
    #         ends in failure. This value should be the
    #         :id of the return value of :queue.
    #       exception: The cause of the failure.
    #       raw_message: the message received.
    #   5. create_queue_backend - optional
    #     Register the queue itself on its backend.
    #     This will be invoked from the rake task
    #     'arsenicum:create_queues'.
    #     Note: this method should be implemented idempotently.
    #
    #####################################################
  end
end
