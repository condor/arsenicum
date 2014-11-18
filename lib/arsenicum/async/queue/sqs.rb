require 'aws-sdk'
require 'multi_json'

class Arsenicum::Async::Queue::Sqs < Arsenicum::Async::Queue
  attr_reader :sqs_queue, :via_sns

  def initialize(name, options = {})
    super name, options
    sqs_args = [options[:aws_account]].tap(&:compact!)
    sqs = AWS::SQS.new *sqs_args
    @sqs_queue = sqs.queues.named(name)
    @via_sns = options[:via_sns]
  end

  def pick
    loop do
      message = sqs_queue.receive_message
      next sleep(0.5) unless message

      message = message.as_sns_message if via_sns
      [
          MultiJson.decode(message.body),
        -> { message.delete },
      ]
    end
  end
end
