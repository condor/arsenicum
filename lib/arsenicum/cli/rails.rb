module Arsenicum
  class CLI::Rails < CLI
    def boot
      ENV['RACK_ENV'] = (ENV['RAILS_ENV'] ||= (configuration[:rails_env] || 'development'))
      rootdir = ENV['RAILS_ROOT'] || configuration[:dir] || Dir.pwd
      Dir.chdir rootdir

      if configuration[:background] && !configuration[:pidfile]
        configuration[:pidfile] = "#{rootdir}/tmp/pids/arsenicum.pid"
      end

      load File.join(rootdir, 'config/environment.rb')
      Arsenicum::Configuration.reconfigure configuration
      Arsenicum::Server.start
    end

    def option_parser
      OptionParser.new.register("-e", "--environment=ENVIRONMENT", -> v { {rails_env: v} }).
        register("-d", "--dir=DIRECTORY", -> v { {dir: v} }).
        register("-p", "--pidfile=PID_FILE", -> v { { pidfile: v } }).
        register("-l", "--log-file=LOG_FILE", -> v { { log_file: v } }).
        register("-D", "--daemon", -> v { { background: true } }).
        register("-L", "--log-level=LOG_LEVEL", -> v { {log_level: v} })
    end
  end
end
