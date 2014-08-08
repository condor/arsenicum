require 'date'
require 'time'

module Arsenicum::Serializer
  DATE_FORMAT = "%Y-%m-%d".freeze
  DATE_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S %Z %z".freeze

  include Arsenicum::Util

  def self.included(base)
    base.__send__ :extend, self
  end

  def serialize_object(value)
    serialize_object_specific(value) || serialize_object_default(value)
  end

  TYPE_RAW      = 'raw'.freeze
  TYPE_DATE     = 'date'.freeze
  TYPE_DATETIME = 'datetime'.freeze
  TYPE_CLASS    = 'class'.freeze
  TYPE_ARRAY    = 'array'.freeze
  TYPE_HASH     = 'hash'.freeze
  TYPE_ANY      = 'marshal'.freeze

  def serialize_object_specific(value)
    case value
      when Integer, Float, String, TrueClass, FalseClass, NilClass
        {
            type: TYPE_RAW,
            value: value.inspect,
        }
      when DateTime, Time
        {
            type: TYPE_DATETIME,
            value: value.strftime(DATE_TIME_FORMAT),
        }
      when Date
        {
            type: TYPE_DATE,
            value: value.strftime(DATE_FORMAT),
        }
      when Class
        {
            type: TYPE_CLASS,
            value: value.name,
        }
      when Array
        {
            type: TYPE_ARRAY,
            values: value.map{|v|serialize_object(v)},
        }
      when Hash
        {
            type: TYPE_HASH,
            values: value.inject({}){|h, kv|(k,v)=kv;h[k.to_s]=serialize_object(v);h},
        }
    end
  end

  def serialize_object_default(value)
    {
        type: TYPE_ANY,
        value: Marshal.dump(value).unpack('H*').first,
    }
  end

  def restore_object(value)
    value = normalize_hash(value)

    return eval value[:value] if value[:type] == TYPE_RAW
    restore_object_specific(value) || restore_object_default(value)
  end

  def restore_object_specific(value)
    case value[:type]
      when TYPE_DATE
        Date.strptime(value[:value], DATE_FORMAT)
      when TYPE_DATETIME
        Time.strptime(value[:value], DATE_TIME_FORMAT)
      when TYPE_CLASS
        Module.const_get value[:value].to_sym
      when TYPE_ARRAY
        value[:values].map do |value|
          restore_object(value)
        end
      when TYPE_HASH
        value[:values].inject({}) do |h, key_value|
          (key, value) = key_value
          h[key.to_sym] = restore_object(key_value)
          h
        end
    end
  end

  def restore_object_default(value)
    Marshal.restore_object [value[:value]].pack('H*')
  end

  module WithActiveRecord
    TYPE_ACTIVE_RECORD = 'active_record'.freeze

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
              type: TYPE_ACTIVE_RECORD,
              class: value.class.name,
              id: value.id,
          } if value.is_a? ActiveRecord::Base
        end

        def restore_object_active_record(value)
          if value[TYPE_CLASS] == TYPE_ACTIVE_RECORD
            klass = const_get value[TYPE_CLASS].to_sym
            klass.find value['id']
          end
        end

        alias_method_chain :serialize_object_specific, :active_record
        alias_method_chain :restore_object_specific, :active_record

      end
    end
  end

end
