class Arsenicum::CLI
  autoload  :RailsCLI, 'arsenicum/cli/rails_cli'

  attr_reader :arguments, :configuration
  private     :arguments, :configuration

  def initialize(arguments)
    @arguments = arguments
    @configuration = create_configuration
    parse_options arguments
  end

  def boot
    create_main.run configuration
  end

  private
  def create_configuration
    Arsenicum::Configuration.new
  end

  def create_main
    Arsenicum::Main.new
  end

  def parse_options(arguments)
    OptionParser.new(&method(:handle_options)).parse!(arguments)
  end

  def handle_options(opt)
    opt.on '-c', '--config-file=CONFIG_FILE', 'Specifies configuration file. all other options will be ignored.' do |config_path|
      config_file = File.expand_path config_path
      script = File.read config_file
      configuration.instance_eval script, config_file, 1
    end

    opt.on '-d', '--daemonize' do
      configuration.daemonize
    end

    opt.on '--stdout=PATH' do |v|
      configuration.stdout    v
    end

    opt.on '--stderr=PATH' do |v|
      configuration.stderr    v
    end
  end

end
