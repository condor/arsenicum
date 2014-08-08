module Arsenicum::Backend::ActiveRecord
  class Publisher < Arsenicum::Backend::Publisher
    def publish(request)
      Arsenicum::ActiveRecord::Model::Queue.create! request.to_h.tap{|h|h.merge! queue_name: queue_name}
    end
  end
end
