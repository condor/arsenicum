module Arsenicum
  module Main
    def run(config_file)
      config = Arsenicum::Configuration.new
      config_file = File.expand_path config_file

      script = File.read config_file
      config.instance_eval script, config_file, 1

      if config.daemon
        Process.daemon

        File.open(config.pidfile_path, 'w:UTF-8') do |f|
          f.puts $$
        end
      end

      configure_io  config
      configure_log config

      threads = config.queue_configurations.map{|qc|qc.build.start_async}

      begin
        threads.each(&:join)
      rescue Interrupt
      end
    end

    private
    def configure_io(config)
      $stdout = File.open(config.stdout_path, 'a:UTF-8') if config.stdout_path

      if config.stderr_path
        if config.stdout_path && config.stdout_path == config.stderr_path
          $stderr = $stdout
        else
          $stderr = File.open(config.stderr_path, 'a:UTF-8')
        end
      end
    end

    def configure_log(config)
      Arsenicum::Logger.configure config.logger_config
    end

    module_function :run, :configure_io,  :configure_log
  end
end
