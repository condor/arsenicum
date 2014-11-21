module Arsenicum
  class Main
    attr_reader :queues

    def run(config)
      $0 = 'arsenicum[main]'

      if config.daemon
        Process.daemon  true, true

        File.open(config.pidfile_path, 'w:UTF-8') do |f|
          f.puts $$
        end
      end

      Dir.chdir     config.working_directory

      configure_io  config
      configure_log config

      before_boot(config)

      @queues = config.queue_configurations.map{|qc|qc.build}
      threads = @queues.map(&:start_async)
      begin
        sleep 10
        trap_signal

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

    def before_boot(config);end

    def configure_log(config)
      Arsenicum::Logger.configure config.logger_config
    end

    def trap_signal
      [:TERM, :INT,].each do |sig|
        queues.each(&:stop)
        exit 1
      end
    end

    autoload  :RailsMain, 'arsenicum/main/rails_main'
  end
end
