require 'json'

module Arsenicum
  module Queueing
    class Request
      include Serializer

      attr_reader :raw_message, :target, :method_name, :arguments, :timestamp, :id

      def self.restore(raw_message, id)
        message_content = JSON(raw_message)

        timestamp = message_content['timestamp']
        method = message_content['method_name'].to_sym

        target = restore_object(message_content['target'])
        arguments = message_content['arguments'].nil? ? [] :
            message_content['arguments'].map{|arg|restore_object(arg)}

        new(target, method, arguments, id: id, timestamp: timestamp, raw_message: raw_message)
      end

      def initialize(target, method_name, arguments = nil,
          timestamp: (Time.now.to_f * 1000000).to_i, id: nil, raw_message: nil)
        @target       = target
        @method_name  = method_name.to_sym
        @arguments    = arguments
        @timestamp    = timestamp
        @id           = id
        @raw_message  = raw_message
      end

      def to_h
        {
            target: serialize_object(target),
            timestamp: timestamp,
            method_name: method_name,
            arguments: arguments.nil? ? nil : arguments.map { |arg| serialize_object(arg) },
        }
      end

      def serialize
        JSON(to_h)
      end

      def execute!
        worker.__send__ method_name, *arguments
      end
    end
  end
end
