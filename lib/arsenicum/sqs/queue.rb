require 'aws-sdk'

module Arsenicum::Sqs
  class Queue < Arsenicum::Queue
    attr_reader :account
    attr_reader :sqs
    attr_reader :wait_timeout
    attr_reader :physical_name

    DEFAULT_WAIT_TIMEOUT = 1
    DELIMITER_PREFIX = '.'.freeze

    def configure(_, engine_config)
      @account = engine_config.account
      @sqs = AWS::SQS.new account
      @wait_timeout = engine_config.wait_timeout ?
          engine_config.wait_timeout.to_i : DEFAULT_WAIT_TIMEOUT
      @physical_name =
          (engine_config.queue_name_prefix ?
              [engine_config.queue_name_prefix, name.to_s].join(DELIMITER_PREFIX) : name).to_sym
    end

    def put_to_queue(json, named: name)
      sqs_queue = sqs.queues.named(named.to_s)
      sqs_queue.send_message(json)
    end

    def poll
      sqs.queues.named(name.to_s).poll(wait_time_out: wait_timeout) do |message|
        {
          body: message.body,
          id: message.handle,
        }.tap{|m|logger.debug { "MESSAGE RECEIVED: #{m.inspect}" } }
      end
    end

    def handle_failure(message_id, exception, raw_message)
      # TODO logging
    end

    def handle_success(message_id)
      sqs_queue = sqs.named(name)
      sqs.client.delete_message queue_url: sqs_queue.url, receipt_handle: message_id
    end

    CREATION_OPTIONS = [
      :visibility_timeout, :maximum_message_size,
      :delay_seconds, :message_retention_period,
    ].freeze
    CREATION_OPTIONS_IN_JSON = [
      :policy,
    ].freeze

    def create_queue_backend
      creation_options = engine_configuration.creation_options.dup

      CREATION_OPTIONS_IN_JSON.each do |opt|
        creation_options[opt] = JSON(creation_options[opt]) if creation_options[opt]
      end

      begin
        sqs.queues.named(name.to_s)
        puts "Not Created Queue #{name}:Exists"
      rescue AWS::SQS::Errors::NonExistentQueue
        sqs.queues.create name.to_s, creation_options
        puts "Created Queue #{name}"
      end
    end
  end
end
