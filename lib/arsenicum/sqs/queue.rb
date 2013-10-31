require 'aws-sdk'

module Arsenicum::Sqs
  class Queue < Arsenicum::Queue
    attr_reader :account
    attr_reader :sqs
    attr_reader :wait_timeout
    attr_reader :failure_queue_name

    def configure(config)
      @account = config[:account]
      @sqs = AWS::SQS.new account
      @wait_timeout =
        if config[:long_poll]
          nil
        elsif config[:wait_timeout]
          config[:wait_timeout].to_i
        end
      @failure_queue_name = config[:failure_queue_name]
    end

    def put_to_queue(json, named: name)
      sqs_queue = sqs.named(named)
      sqs_queue.send_message(json)
    end

    def poll
      sqs.named(name).poll(wait_time_out: wait_timeout) do |message|
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
  end
end
