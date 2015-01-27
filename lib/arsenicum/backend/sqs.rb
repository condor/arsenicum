module Arsenicum::Backend
  module Sqs
    def pick
      message = sqs_message = sqs_queue.receive_message
      return unless message
      message = message.as_sns_message if via_sns

      [MultiJson.decode(message.body), sqs_message]
    end

    def handle_success(original_message)
      original_message.delete
    end
  end

  autoload  :ConditionalQueue,  'lib/arsenicum/backend/sqs/conditional_queue'
  autoload  :S3EventQueue,      'lib/arsenicum/backend/sqs/s3_event_queue'
end
