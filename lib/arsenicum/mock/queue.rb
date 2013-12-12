module Arsenicum
  module Mock
    class Queue < Arsenicum::Queue

      attr_reader :queues

      def configure(*)
        @queues = Array.new
      end

      def put_to_queue(json, named: name)
        queues << json
      end

      def receive
        {
            body: queues.shift,
            id: Time.now.to_f.to_s,
        }
      end

      def handle_failure(*)
        # TODO logging
      end

      def handle_success(*)
      end

    end
  end
end