module Arsenicum
  class Main
    attr_reader :config

    class << self
      def run(config, main_class: Arsenicum::Main)
        main = main_class.new config
        main.run
      end

      private
      def attr_config_reader(*attr_names)
        attr_names.each do |attr_name|
          class_eval <<-SCRIPT, __FILE__, __LINE__ + 1
          def #{attr_name}
            config.#{attr_name}
          end
          SCRIPT
        end
      end
    end

    def initialize(config)
      @config = config
      configure
    end

    def run(config)
      rename_process
      trap_signal
      daemonize_if_required
      move_directory

      configure_io
      configure_log

      before_boot
      boot

      waiting_loop
    end

    private
    def configure;end

    def rename_process
      $0 = "#{process_name}[main]"
    end

    def move_directory
      Dir.chdir     config.working_directory
    end

    def daemonize_if_required
      return unless config.daemon

      Process.daemon  true, true

      File.open(config.pidfile_path, 'w:UTF-8') do |f|
        f.puts $$
      end
    end

    def configure_io
      $stdout = File.open(config.stdout_path, 'a:UTF-8') if config.stdout_path

      if config.stderr_path
        if config.stdout_path && config.stdout_path == config.stderr_path
          $stderr = $stdout
        else
          $stderr = File.open(config.stderr_path, 'a:UTF-8')
        end
      end
    end

    def configure_log
      Arsenicum::Logger.set_logger config.logger_config.build
    end

    def before_boot;end

    def trap_signal
      [:TERM, :INT,].each do |sig|
        Signal.trap sig do
          queues.each(&:stop)
          exit 1
        end
      end
    end

    def process_name
      'arsenicum'
    end

    def waiting_loop
      begin
        loop{sleep 100}
      rescue Interrupt
      end
    end

    autoload  :RailsMain, 'arsenicum/main/rails_main'
    autoload  :Queue,     'arsenicum/main/queue'
  end
end
