class Arsenicum::Async::Queue < Arsenicum::Core::Broker

  attr_accessor :broker
  attr_reader   :name

  def initialize(name)
    @name = name
  end

  def start
    loop do
      message = pick
      next sleep(0.5) unless message

      broker.delegate message
    end
  end

  autoload  :SQS, 'arsenicum/async/queue/sqs'
end
