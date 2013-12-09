module Arsenicum
  class CLI::Rails < CLI
    include Arsenicum::Util

    def boot
      configuration = self.configuration
      server_config = configuration.delete(:server)

      rails_env = server_config.delete(:environment) || ENV['RAILS_ENV'] || :development
      rails_env = rails_env.to_sym
      dir = server_config.delete(:working_directory) || ENV['RAILS_ROOT'] || Dir.pwd
      dir = File.expand_path dir
      background = server_config.delete(:background)
      pidfile = server_config.delete(:pidfile) || "#{dir}/tmp/pids/arsenicum.pid" if background

      Dir.chdir dir
      config_for_env = server_config[rails_env]
      raise Arsenicum::MisconfigurationError, "config for #{rails_env} is abscent" unless config_for_env

      config_for_env.merge!(
          server: {
              environment: environment,
              working_directory: dir,
              pidfile: pidfile,
              background: background,
          },
      )

      ENV['RAILS_ENV'] = rails_env.to_s
      load File.join(dir, 'config/environment.rb')
      Arsenicum::Configuration.configure config_for_env
      Arsenicum::Processing::Server.start
    end

    private
    def option_parser
      OptionParser.new.
        register("-e", "--environment=ENV", -> v {{rails_env: v}}).
        register("-d", "--rails-root=DIR", -> v {{working_directory: v}}).
        register("-c", "--config-file=FILE",
                 -> v {v.end_with?(".yml") ? YAML.load(File.read v, encoding: 'UTF-8') : load(v)})
    end
  end
end
