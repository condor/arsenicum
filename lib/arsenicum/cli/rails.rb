module Arsenicum
  class CLI::Rails < CLI
    def boot
      ENV['RACK_ENV'] = ENV['RAILS_ENV'] = (configuration[:rails_env] || 'development')
      require 'rails'
      super
    end

    def option_parser
      super.register("-e", "--environment=ENVIRONMENT", -> v { {rails_env: v} })
    end
  end
end
