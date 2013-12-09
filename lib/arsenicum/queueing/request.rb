require 'json'

module Arsenicum
  module Queueing
    class Request
      include Serialization

      attr_reader :target, :method, :arguments, :timestamp, :message_id, :exception

      def self.parse(raw_message, message_id)
        message_content = JSON(raw_message)

        timestamp = message_content['timestamp']
        method = message_content['method_name'].to_sym

        target = restore(message_content['target'])
        arguments = message_content['arguments'].nil? ? [] :
            message_content['arguments'].map{|arg|restore(arg)}

        new(target, method, arguments, timestamp, message_id)
      end

      def initialize(target, method, arguments, timestamp, message_id)
        @target     = target
        @method     = method
        @arguments  = arguments
        @timestamp  = timestamp
        @message_id = message_id
      end

      def prepare_serialization
        {
            target: prepare_serialization(target),
            timestamp: (Time.now.to_f * 1000000).to_i,
            method_name: method_name,
            arguments: arguments.nil? ? nil : arguments.map{|arg|prepare_serialization(arg)},
        }
      end

      def serialize
        JSON(prepare_serialization)
      end

      def execute!
        target.__send__ method, *arguments
      rescue Exception => e
        @exception = e
      end

      def successful?
        !exception
      end
    end
  end
end
