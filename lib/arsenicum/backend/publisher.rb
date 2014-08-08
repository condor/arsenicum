module Arsenicum::Backend
  class Publisher
    attr_reader :queue_name

    def initialize(queue_name, publication_config)
      @queue_name = queue_name
      configure publication_config
    end
    def configure(_);end
  end
end
