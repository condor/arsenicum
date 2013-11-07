module Arsenicum::Syntax
  module DelayedJob
    class DelayedObject < BasicObject
      def initialize(wrapped_object)
        @wrapped_object = wrapped_object
      end

      def method_missing(method_id, *arguments)
        Arsenicum::QueueProxy.instance.async(@wrapped_object, method_id, *arguments)
      end
    end

    module ObjectExt
      def delay
        DelayedObject.new(self)
      end
    end

    class <<self
      def enable!
        Object.__send__(:include, ObjectExt)
      end
    end
  end
end
