module Arsenicum
  class CLI::Rails < CLI
    include Arsenicum::Util

    def boot
      configuration = self.configuration

      rails_env = configuration.delete(:rails_env)
      dir = configuration.delete(:dir)
      pidfile = configuration.delete(:pidfile)
      background = configuration.delete(:background)

      ENV['RACK_ENV'] = (ENV['RAILS_ENV'] ||= (rails_env || :development))
      dir = ENV['RAILS_ROOT'] || dir || Dir.pwd
      Dir.chdir dir

      pidfile = "#{dir}/tmp/pids/arsenicum.pid" if background && !pidfile

      config_for_env = configuration[ENV['RAILS_ENV']]
      config_for_env.merge!(
          dir: dir,
          pidfile: pidfile,
          background: background,
      )

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
