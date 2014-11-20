class Arsenicum::Main::RailsMain < Arsenicum::Main
  def before_boot(config)
    env = config.rails_env || 'development'
    ENV['RAILS_ENV'] = env.to_s

    require './config/environment'
  end
end
