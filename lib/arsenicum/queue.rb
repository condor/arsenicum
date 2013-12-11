require 'json'

module Arsenicum
  class Queue
    DEFAULT_CONCURRENCY = 5

    attr_reader   :name, :concurrency, :logger, :config, :engine_config

    def initialize(name, logger: nil, config: nil, engine_config: nil)
      @name = name
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
    #   2. poll: polling the queue and retrieve the
    #     message information. This method is expected to
    #     return the message Hash. Its keys and values
    #     are expected as below:
    #       :body: the raw string that was pushed
    #         via the :put_to_queue method.
    #       :id: the identifier of this message.
    #         This is usually used to update the status of
    #         message on the queue backend.
    #   3. handle_success(message_id):
    #     The post-success process. Arguments are as below:
    #       message_id: The identifier of the message processed.
    #   4. handle_failure(message_id, exception, raw_message):
    #     The process if the task finishes in failure.
    #     Arguments are:
    #       message_id: The identifier of the message that
    #         ends in failure. This value should be the
    #         :message_id of the return value of :poll.
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
