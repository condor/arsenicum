class Arsenicum::Runner

  def initialize(server_class)
    @server_class = server_class
  end

  def run(configuration)
    @server_class.new(configuration).start

    Thread.join
  end
end
