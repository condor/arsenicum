require 'weakref'

class Arsenicum::Core::Worker
  include Arsenicum::Core::Commands
  include Arsenicum::Core::IOHelper

  attr_reader :pid, :in_parent, :out_parent, :thread,
              :in_child,  :out_child, :active, :broker, :serializer,  :formatter, :index
  alias_method :active?, :active

  def initialize(broker, index, worker_configuration)
    @broker     = WeakRef.new broker # avoiding circular references.
    @index      = index
    @serializer = worker_configuration[:serializer]
    @formatter  = worker_configuration[:formatter]
    @thread     = InvokerThread.new(self)
  end

  def run
    (@in_parent, @out_child) = open_binary_pipes
    (@in_child, @out_parent) = open_binary_pipes

    @pid = fork do
      $0 = "arsenicum[worker][#{index}]"
      [in_parent, out_parent].each(&:close)

      begin
        loop do
          begin
            Arsenicum::Logger.debug {log_message_for '[child]to read initial command'}
            command = read_code in_child
            Arsenicum::Logger.debug {log_message_for '[child]Command: 0x%02x' % command}
            break if command == COMMAND_STOP
            task_id_string  = read_string in_child
            content         = read_string in_child
          rescue Arsenicum::IO::EOFException
            # Interrupted request: No required GC.
            break
          end

          task_id         = task_id_string.to_sym
          task            = broker[task_id]

          parameters      = deserialize content

          begin
            Arsenicum::Logger.info {log_message_for "[child]Task start"}
            Arsenicum::Logger.info {log_message_for "[child]Parameters: #{parameters.inspect}"
            task.run      *parameters
            Arsenicum::Logger.info {log_message_for "[child]Task success"}
            write_code    out_child,  0
          rescue Exception => e
            Arsenicum::Logger.error {log_message_for "[child]Task Failure with #{e.class.name}#{":#{e.message}" if e.message}"}
            write_code    out_child,  1
            write_string  out_child,  Marshal.dump(e)
          end
        end
      ensure
        [in_child, out_child].each do |io|
          begin io.close rescue nil end
        end
      end
    end
    @active = true
    [in_child, out_child].each(&:close)
    pid
  end

  def open_binary_pipes
    IO.pipe.each do |io|
      io.set_encoding 'BINARY'
    end
  end

  def ask_async(success_handler, failure_handler, task_id, *parameters)
    thread.ask success_handler, failure_handler, task_id, *parameters
  end

  def ask(task_id, *parameter)
    Arsenicum::Logger.info {log_message_for "Task ID: #{task_id}"}

    write_code    out_parent, COMMAND_TASK
    write_string  out_parent, task_id.to_s
    write_string  out_parent, serialize(parameter)

    Arsenicum::Logger.debug { log_message_for "Task ID: #{task_id}: Request completed. Begin waiting for the reply." }

    result = read_code     in_parent
    return if result == 0
    raise Marshal.restore(read_string in_parent, encoding: 'BINARY')
  ensure
    return_to_broker
  end

  def stop
    write_code    out_parent, COMMAND_STOP
    Process.waitpid pid
  end

  private
  def serialize(parameter)
    serializer.serialize(formatter.format(parameter))
  end

  def deserialize(string)
    formatter.parse(serializer.deserialize(string))
  end

  def trap_signal
    %w(TERM INT).each do |sig|
      Signal.trap sig do
        exit 5
      end
    end
  end

  def return_to_broker
    broker.get_back_worker self
  end

  def log_message_for(message)
    "[Worker ##{object_id}]#{message}"
  end

  class InvokerThread < Thread
    attr_accessor :task_request
    private       :task_request,  :task_request=

    def ask(success_handler, failure_handler, task_id, *parameters)
      self.task_request = [success_handler, failure_handler, task_id, parameters]
    end

    def initialize(worker)
      super do
        loop do
          next sleep(0.5) unless task_request
          (success_handler, failure_handler, task_id, parameter) = task_request

          begin
            worker.ask task_id, *parameter
            success_handler.call
          rescue Exception => e
            Arsenicum::Logger.error {log_message_for worker, "Exception: #{e.class.name}"}
            failure_handler.call e
          ensure
            self.task_request = nil
          end
        end
      end
    end

    def log_message_for(worker, message)
      "[Worker ##{worker.object_id}][thread]#{message}"
    end
  end
end
