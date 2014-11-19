require 'weakref'

class Arsenicum::Routing::Router
  attr_reader :broker

  def initialize(broker)
    @broker = WeakRef.new broker
  end
end
