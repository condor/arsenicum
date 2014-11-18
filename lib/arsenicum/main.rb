module Arsenicum
  module Main
    def run(config_file)
      config = Arsenicum::Configuration.new
      config_file = File.expand_path config_file

      script = File.read config_file
      config.instance_eval script, config_file, 1

      File.open(config.pidfile_path, 'w:UTF-8') do |f|
        f.puts $$
      end
      threads = config.build_queues.map(&:start_async)
      threads.each(&:join)
    end

    module_function :run
  end
end
