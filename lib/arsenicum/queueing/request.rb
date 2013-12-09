require 'json'

module Arsenicum
  module Queueing
    class Request
      include Serializer

      attr_reader :target, :method, :arguments, :timestamp, :message_id, :exception

      def self.restore(raw_message, message_id)
        message_content = JSON(raw_message)

        timestamp = message_content['timestamp']
        method = message_content['method_name'].to_sym

        target = restore_object(message_content['target'])
        arguments = message_content['arguments'].nil? ? [] :
            message_content['arguments'].map{|arg|restore_object(arg)}

        new(target, method, arguments, timestamp, message_id)
      end

      def initialize(target, method, arguments, timestamp, message_id)
        @target     = target
        @method     = method
        @arguments  = arguments
        @timestamp  = timestamp
        @message_id = message_id
      end


      def serialize
        JSON(
            target: serialize_object(target),
            timestamp: (Time.now.to_f * 1000000).to_i,
            method_name: method_name,
            arguments: arguments.nil? ? nil : arguments.map { |arg| serialize_object(arg) },
        )
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
