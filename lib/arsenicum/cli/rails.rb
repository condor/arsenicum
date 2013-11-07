module Arsenicum
  class CLI::Rails < CLI
    def boot
      ENV['RACK_ENV'] = ENV['RAILS_ENV'] = (configuration[:rails_env] || 'development')
      ENV['RAILS_ROOT'] ||= (configuration[:dir] || Dir.pwd)
      load File.join(ENV['RAILS_ROOT'], 'config/environment.rb')
      super
    end

    def option_parser
      super.register("-e", "--environment=ENVIRONMENT", -> v { {rails_env: v} }).
        register("-d", "--dir=DIRECTORY", -> v { {dir: v} })
    end
  end
end
