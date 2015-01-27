class Arsenicum::BootStrap

  def initialize(configuration_attributes)
    @config = Arsenicum::Configuration.new configuration_attributes
  end

  def start
    setup
    run
  end

  def setup
  end

  def run
    log_path = @config.log_path

    @server = server_class.new @config.server
  end

  private
  def server_class
    queue_type = Arsenicum::Util.camelcase @config.queue_type
    Arsenicum::Util.constantize queue_type, inside: Arsenicum::Server
  rescue NameError
    Arsenicum::Util.constantize queue_type
  end
end
