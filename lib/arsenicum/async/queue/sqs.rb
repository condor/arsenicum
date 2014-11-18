require 'multi_json'

class Arsenicum::Async::Queue::SQS < Arsenicum::Async::Queue
  attr_reader :sqs_queue, :via_sns

  def initialize(name, options = {})
    super name
    sqs = AWS::SQS.new options[:aws_account]
    @sqs_queue = sqs.queues.named(name)
    @via_sns = options[:via_sns]
  end

  def pick
    loop do
      message = sqs_queue.receive_message
      message = message.as_sns_message if via_sns

      MultiJson.decode message.body
    end
  end
end
