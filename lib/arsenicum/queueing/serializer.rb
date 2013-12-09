require 'date'
require 'time'

module Arsenicum
  module Queueing
    module Serializer
      DATE_FORMAT = "%Y-%m-%d".freeze
      DATE_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S %Z %z".freeze

      def serialize_object(value)
        serialize_object_specific(value) || serialize_object_default(value)
      end

      def serialize_object_specific(value)
        case value
          when Integer, Float, String, TrueClass, FalseClass, NilClass
            {
                type: :raw,
                value: value.inspect,
            }
          when Date
            {
                type: 'date',
                value: value.strftime(DATE_FORMAT),
            }
          when DateTime, Time
            {
                type: 'time',
                value: value.strftime(DATE_TIME_FORMAT),
            }
          when Class
            {
                type: :class,
                value: value.name,
            }
          when Array
            {
                type: :array,
                values: value.map{|v|serialize_object(v)},
            }
          when Hash
            {
                type: :hash,
                values: value.inject({}){|h, kv|(k,v)=kv;h[k.to_s]=serialize_object(v);h},
            }
        end
      end

      def serialize_object_default(value)
        {
            type: 'marshal',
            value: Marshal.dump(value).unpack('H*').first,
        }
      end

      def restore_object(value)
        return eval value['value'] if value['type'] == 'raw'
        restore_object_specific(value) || restore_object_default(value)
      end

      def restore_object_specific(value)
        case value['type']
          when 'date'
            Date.strptime(value['value'], DATE_FORMAT)
          when 'time'
            Time.strptime(value['value'], DATE_TIME_FORMAT)
          when 'class'
            Module.const_get value['value'].to_sym
          when 'array'
            value['values'].map do |value|
              restore_object(value)
            end
          when 'hash'
            value['values'].inject({}) do |h, key_value|
              (key, value) = key_value
              h[key.to_sym] = restore_object(key_value)
              h
            end
        end
      end

      def restore_object_default(value)
        Marshal.restore_object [value['value']].pack('H*')
      end

      module WithActiveRecord
        def self.included(base)
          base.module_eval do
            def serialize_object_specific_with_active_record(value)
              serialize_object_specific_without_active_record(value) || serialize_object_active_record(value)
            end

            def restore_object_specific_with_active_record(value)
              restore_object_specific_without_active_record(value) || restore_object_active_record(value)
            end

            private
            def serialize_object_active_record(value)
              return {
                  type: :active_record,
                  class: value.class.name,
                  id: value.id,
              } if value.is_a? ActiveRecord::Base
            end

            def restore_object_active_record(value)
              if value['class'] == 'active_record'
                klass = const_get value['class'].to_sym
                klass.find value['id']
              end
            end

            alias_method_chain :serialize_object_specific, :active_record
            alias_method_chain :restore_object_specific, :active_record

          end
        end
      end

    end
  end
end
