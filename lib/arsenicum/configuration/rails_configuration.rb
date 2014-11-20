class Arsenicum::Configuration::RailsConfiguration < Arsenicum::Configuration
  attr_reader :rails_env

  def initialize(*)
    super
    @rails_env  = 'development'
  end

  def environment(env_name)
    @rails_env = env_name
  end
end
