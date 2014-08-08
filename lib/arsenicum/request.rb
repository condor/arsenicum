require 'json'

module Arsenicum
  class Request
    include Serializer

    attr_reader :original, :target, :method_name, :arguments, :timestamp, :id, :raw_data

    def self.restore(raw_message, id, raw: false)
      message_content = JSON(raw_message)

      if raw
        raw_data = message_content
      else
        timestamp = message_content['timestamp']
        method = message_content['method_name'].to_sym

        target = restore_object(message_content['target'])
        arguments = message_content['arguments'].nil? ? [] :
            message_content['arguments'].map{|arg|restore_object(arg)}
      end

      new(
          target: target, method_name: method, arguments: arguments,
          id: id, timestamp: timestamp, original: raw_message,
          raw_data: raw_data,
      )
    end

    def initialize(target: nil, method_name: nil, arguments: nil,
        timestamp: (Time.now.to_f * 1000000).to_i, id: nil, original: nil, raw_data: nil)
      @target       = target
      @method_name  = method_name.to_sym
      @arguments    = arguments
      @timestamp    = timestamp
      @id           = id
      @original     = original
      @raw_data     = raw_data
    end

    def to_h
      return raw_data.to_h if raw_data

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
