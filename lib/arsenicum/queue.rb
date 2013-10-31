require 'json'

module Arsenicum
  class Queue
    DEFAULT_CONCURRENCY = 5

    attr_reader :name, :concurrency, :queue_methods, :queue_classes

    def initialize(config = {})
      @name = config.delete :name
      @concurrency = config.delete(:concurrency) || DEFAULT_CONCURRENCY
      @queue_methods = config.delete(:methods)
      @queue_classes = config.delete(:classes)
      configure(config)
    end

    def put(hash)
      json = JSON(hash.merge(timestamp: Time.to_f.to_s.tap{|t|t.sub! '.', ''}))
      put_to_queue(json)
    end
  end
end
