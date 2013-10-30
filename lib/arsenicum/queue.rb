require 'json'

module Arsenicum
  class Queue
    attr_reader :name

    def initialize(arguments = {})
      @name = arguments[:name]
    end

    def put(hash)
      json = JSON(hash.merge(timestamp: Time.to_f.to_s.tap{|t|t.sub! '.', ''}))
      put_to_queue(json)
    end
  end
end
