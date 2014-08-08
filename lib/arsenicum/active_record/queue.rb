require 'aws-sdk'

module Arsenicum::ActiveRecord
  class Queue < Arsenicum::Queue
    attr_reader :actual_name

    attr_reader :engine_config
    private     :engine_config

    DEFAULT_WAIT_TIMEOUT = 1
    DELIMITER_PREFIX = '-'.freeze

    def configure(_, engine_config)
      @engine_config = engine_config
      @sqs = AWS::SQS.new account
      @actual_name =
          (engine_config.queue_name_prefix ?
              [engine_config.queue_name_prefix, name.to_s].join(DELIMITER_PREFIX) : name).to_s
    end

    def put_to_queue(json)
      sqs_queue = sqs.queues.named(actual_name)
      sqs_queue.send_message(json)
    end

    def receive
      message = sqs.queues.named(actual_name).receive_message
      {
        body: message.body,
        id: message.handle,
      }.tap{|m|logger.debug { "MESSAGE RECEIVED: #{m.inspect}" } } if message
    end

    def handle_failure(id, exception, raw_message)
      logger.error "Message ##{id} failure; exception with #{exception.inspect}, message #{raw_message}"
      logger.info exception.backtrace.join("\n")
    end

    def handle_success(id)
      sqs_queue = sqs.queues.named(actual_name)
      sqs.client.delete_message queue_url: sqs_queue.url, receipt_handle: id
    end

    CREATION_OPTIONS = [
      :visibility_timeout, :maximum_message_size,
      :delay_seconds, :message_retention_period,
    ].freeze
    CREATION_OPTIONS_IN_JSON = [
      :policy,
    ].freeze

    def account
      engine_config.account
    end

    def create_queue_backend
      if engine_config.queue_creation_options
        creation_options = engine_config.queue_creation_options.dup

        CREATION_OPTIONS_IN_JSON.each do |opt|
          creation_options[opt] = JSON(creation_options[opt]) if creation_options[opt]
        end
      else
        creation_options = {}
      end

      begin
        sqs.queues.named(actual_name)
        puts "Not Created Queue #{name}:Exists"
      rescue AWS::SQS::Errors::NonExistentQueue
        sqs.queues.create actual_name, creation_options
        puts "Created Queue #{name}"
      end
    end
  end
end
