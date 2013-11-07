require 'aws-sdk'

module Arsenicum::Sqs
  class Queue < Arsenicum::Queue
    attr_reader :account
    attr_reader :sqs
    attr_reader :wait_timeout
    attr_reader :failure_queue_name
    attr_reader :queue_configuration

    def configure(config)
      @account = config.delete :account
      @sqs = AWS::SQS.new account
      @wait_timeout =
        if config.delete(:long_poll)
          nil
        elsif timeout = config.delete(:wait_timeout)
          timeout.to_i
        end
      @failure_queue_name = config.delete :failure_queue_name

      @queue_configuration = config
    end

    def put_to_queue(json, named: name)
      sqs_queue = sqs.queues.named(named)
      sqs_queue.send_message(json)
    end

    def poll
      sqs.queues.named(name).poll(wait_time_out: wait_timeout) do |message|
        {
          message_body: message.body,
          message_id: message.handle,
        }
      end
    end

    def update_message_status(json, message_id, successful)
      put_to_queue(json, named: failure_queue_name) unless successful

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
      creation_options = queue_configuration.values_at(*CREATION_OPTIONS).
        each_with_index.inject({}) do |opts, vi|

        (value, i) = vi
        opts[CREATION_OPTIONS[i]] = value if value
        opts
      end
      CREATION_OPTIONS_IN_JSON.each do |opt|
        creation_options[opt] = JSON(queue_configuration[opt]) if queue_configuration[opt]
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
