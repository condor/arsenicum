module Arsenicum
  class CLI::Rails < CLI
    include Arsenicum::Util

    def boot
      configuration = self.configuration

      rails_env = configuration.delete(:rails_env) || ENV['RAILS_ENV'] || :development
      rails_env = rails_env.to_sym
      dir = configuration.delete(:dir) || ENV['RAILS_ROOT'] || Dir.pwd
      background = configuration.delete(:background)
      pidfile = configuration.delete(:pidfile) || "#{dir}/tmp/pids/arsenicum.pid" if background

      Dir.chdir dir
      config_for_env = configuration[rails_env]
      raise Arsenicum::MisconfigurationError, "config for #{rails_env} is abscent" unless config_for_env

      config_for_env.merge!(
          dir: dir,
          pidfile: pidfile,
          background: background,
      )

      ENV['RAILS_ENV'] = rails_env.to_s
      load File.join(dir, 'config/environment.rb')
      Arsenicum::Configuration.configure config_for_env
      Arsenicum::Server.start
    end

    private
    def option_parser
      OptionParser.new.
        register("-e", "--environment=ENV", -> v {{rails_env: v}}).
        register("-d", "--rails-root=DIR", -> v {{dir: v}}).
        register("-c", "--config-file=FILE",
                 -> v {v.end_with?(".yml") ? YAML.load(File.read v, encoding: 'r:UTF-8') : load(v)})
    end
  end
end
