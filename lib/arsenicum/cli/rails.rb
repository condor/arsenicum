module Arsenicum
  class CLI::Rails < CLI
    include Arsenicum::Util

    def boot
      configuration = self.configuration
      environment = ENV['RAILS_ENV'] || :development
      environment = environment.to_sym
      config_for_env = configuration[environment]
      raise Arsenicum::MisconfigurationError, "config for #{environment} is abscent" unless config_for_env

      server_config = config_for_env.delete(:server) || {}
      server_config.merge!(configuration.delete(:server) || {})

      dir = server_config.delete(:working_directory) || ENV['RAILS_ROOT'] || Dir.pwd
      dir = File.expand_path dir
      background = server_config.delete(:background)
      pidfile = server_config.delete(:pidfile) || "#{dir}/tmp/pids/arsenicum.pid" if background

      Dir.chdir dir

      config_for_env.merge!(
          server: {
              environment: environment,
              working_directory: dir,
              pidfile: pidfile,
              background: background,
          },
      )

      load File.join(dir, 'config/environment.rb')
      Arsenicum::Configuration.configure config_for_env
      Arsenicum::Processing::Server.start
    end

    private
    def option_parser
      OptionParser.new.
        register("-e", "--environment=ENV", -> v, _ {ENV['RAILS_ENV'] = v.to_s}).
        register("-d", "--rails-root=DIR", -> v, h {h[:server]||={};h[:server].merge!(working_directory: v)}).
        register("-c", "--config-file=FILE",
                 -> v {v.end_with?(".yml") ? YAML.load(File.read v, encoding: 'UTF-8') : load(v)})
    end
  end
end
