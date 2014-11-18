require 'date'
require 'time'

class Arsenicum::Formatter
  DATE_FORMAT = '%Y-%m-%d'.freeze
  DATE_TIME_FORMAT = '%Y-%m-%dT%H:%M:%S %Z %z'.freeze

  include Arsenicum::Util

  def format(value)
    format_for_embedded_classes(value) ||
        format_by_extension(value) ||
        format_by_default(value)
  end

  TYPE_RAW      = 'raw'.freeze
  TYPE_DATE     = 'date'.freeze
  TYPE_DATETIME = 'datetime'.freeze
  TYPE_CLASS    = 'class'.freeze
  TYPE_ARRAY    = 'array'.freeze
  TYPE_HASH     = 'hash'.freeze
  TYPE_ANY      = 'marshal'.freeze

  def format_for_embedded_classes(value)
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

  def format_by_extension(value)
    nil
  end

  def format_by_default(value)
    {
        type: TYPE_ANY,
        value: Marshal.dump(value).unpack('H*').first,
    }
  end

  def parse_object(value)
    value = normalize_hash(value)

    return eval value[:value] if value[:type] == TYPE_RAW
    parse_for_embedded_classes(value) ||
        parse_by_extension(value) ||
        parse_by_default(value)
  end

  def parse_for_embedded_classes(value)
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

  def parse_by_extension(_)
    nil
  end

  def parse_by_default(value)
    ::Marshal.restore [value[:value]].pack('H*')
  end

  class ActiveRecord < ::Arsenicum::Formatter
    TYPE_ACTIVE_RECORD = 'active_record'.freeze

    def format_by_extension(value)
      return {
          type: TYPE_ACTIVE_RECORD,
          class: value.class.name,
          id: value.id,
      } if value.is_a? ActiveRecord::Base
    end

    def parse_by_extension(value)
      if value[:type] == TYPE_ACTIVE_RECORD
        klass = constaitize value[:class].to_sym
        klass.find value[:id]
      end
    end
  end

end
