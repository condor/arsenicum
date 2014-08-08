module Arsenicum::Backend::ActiveRecord
  class Publisher
    def initialize(configuration)
      super
    end

    def publish(request)
      Arsenicum::ActiveRecord::Model::Queue.create! request.to_h
    end
  end
end
