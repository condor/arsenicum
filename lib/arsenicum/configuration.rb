require 'logger'

module Arsenicum
  class MisconfigurationError < StandardError;end

  class Configuration < Hash
    def method_missing(method_id, *args)
      return super if args.length > 1

      method_name = method_id.to_s

      if method_name =~ /=$/
        return super unless args.length == 1
        return (self[method_id] = args.first)
      end

      return super if args.length > 0

      return super if method_name =~ /^to_/

      self[method_id]
    end

    def initialize(args = {})
      raise ArgumentError if args && !args.is_a?(Hash)

      klass = self.class
      super() do |h, k|
        h[k] = klass.new
      end

      merge! args if args
    end

    def merge(another)
      self.class.new(self).merge!(another)
    end

    def merge!(another)
      another.each do |key, value|
        value =
            case value
              when Hash
                self.class.new value
              else
                value
            end

        self[key.to_sym] = value
      end
      self
    end

    def []=(key, value)
      key = key.to_sym
      return super unless has_key? key

      case value
        when Hash
          self[key].merge! value
        else
          super(key, value)
      end
   end
  end
end
