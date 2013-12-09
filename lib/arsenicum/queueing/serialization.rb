require 'date'
require 'time'

module Arsenicum
  module Queueing
    module Serialization
      DATE_FORMAT = "%Y-%m-%d".freeze
      DATE_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S %Z %z".freeze

      def prepare_serialization(value)
        hash_value = prepare_serialization_specific(value) || prepare_serialization_default(value)
      end

      def prepare_serialization_specific(value)
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
                values: value.map{|v|serialize(v)},
            }
          when Hash
            {
                type: :hash,
                values: value.inject({}){|h, kv|(k,v)=kv;h[k.to_s]=serialize(v);h},
            }
        end
      end

      def prepare_serialization_default(value)
        {
            type: 'marshal',
            value: Marshal.dump(value).unpack('H*').first,
        }
      end

      module_function :prepare_serialization_specific, :prepare_serialization_default, :prepare_serialization

      module WithActiveRecord
        def self.included(base)
          base.module_eval do
            alias_method :prepare_serialization_specific_original, :prepare_serialization_specific

            def prepare_serialization_specific(value)
              prepare_serialization_specific_original(value) || prepare_serialization_active_record(value)
            end

            private
            def prepare_serialization_active_record(value)
              return {
                  type: :active_record,
                  class: value.class.name,
                  id: value.id,
              } if value.is_a? ActiveRecord::Base
            end

            module_function :prepare_serialization_specific_original, :prepare_serialization_active_record
          end
        end
      end

      include(WithActiveRecord) if defined? ::ActiveRecord::Base

      def restore(value)
        case value['type']
          when 'raw'
            eval value['value']
          when 'date'
            Date.strptime(value['value'], DATE_FORMAT)
          when 'time'
            Time.strptime(value['value'], DATE_TIME_FORMAT)
          when 'class'
            Module.const_get value['value'].to_sym
          when 'active_record'
            klass = const_get value['class'].to_sym
            klass.find value['id']
          when 'array'
            value['values'].map do |value|
              restore(value)
            end
          when 'hash'
            value['values'].inject({}) do |h, key_value|
              (key, value) = key_value
              h[key.to_sym] = restore(key_value)
              h
            end
          else
            Marshal.restore [value['value']].pack('H*')
        end
      end
    end
  end
end
