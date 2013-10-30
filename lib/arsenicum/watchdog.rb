require 'json'

module Arsenicum
  class WatchDog
    attr_reader :queue
    attr_reader :configuration
    attr_reader :child_processes

    DEFAULT_CONFIGURATION = {
      max_processes: 5
    }

    def initialize(queue, configuration = nil)
      @queue = queue
      @configuration = DEFAULT_CONFIGURATION.merge configuration
      @child_processes = []
      @mutex = Mutex.new
    end

    def monitor
      while message = queue.poll
        while(!process_available?)
          sleep 1
        end

        begin
          pid = fork do
            begin
              target.__send__ method_name, *arguments
              queue.notify_completed(message)
            rescue Exception => e
              # TODO logging
              queue.notify_failure(message)
              raise
            end
            exit
          end
          @mutex.synchronize do
            child_processes << pid if pid && !Process.waitpid(pid, Process::WNOHANG)
          end
        rescue Exception => e
          # TODO logging: fork failure
        end
      end
    end

    def process_available?
      child_processes.count < configuration[:max_processes]
    end

    def check_process_termination
      @mutex.synchronize do
        child_processes.each do |pid|
          child_processes.delete(pid) if Process.waitpid(pid, Process::WNOHANG)
        end
      end
    end
  end
end
