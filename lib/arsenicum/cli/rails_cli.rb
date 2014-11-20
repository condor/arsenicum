require 'optparse'

class Arsenicum::CLI::RailsCLI < Arsenicum::CLI
  private
  def create_configuration
    ::Arsenicum::Configuration::RailsConfiguration.new
  end

  def create_main
    ::Arsenicum::Main::RailsMain.new
  end

  def handle_options(opt)
    super

    opt.on('-e', '--environment=ENVIRONMENT') do |env|
      configuration.environment env
    end
  end
end
