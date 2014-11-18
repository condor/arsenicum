require 'weakref'

class Arsenicum::Core::Worker
  include Arsenicum::Core::Commands
  include Arsenicum::Core::IOHelper

  attr_reader :pid, :in_parent, :out_parent,
              :in_child,  :out_child, :active, :broker, :serializer,  :formatter
  alias_method :active?, :active

  def initialize(broker, worker_configuration)
    @broker = WeakRef.new broker # avoiding circular references.
    @serializer = worker_configuration[:serializer]
    @formatter  = worker_configuration[:formatter]
  end

  def run
    (@in_parent, @out_child) = IO.pipe
    (@in_child, @out_parent) = IO.pipe

    @pid = fork do
      [in_parent, out_parent].each(&:close)

      begin
        loop do
          begin
            command = read_code in_child
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
          parameters      = parameters if parameters.is_a? Hash

          begin
            task.run      *parameters
            write_code    out_child,  0
          rescue Exception => e
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

  def ask(task_id, parameter)
    write_code    out_parent, COMMAND_TASK
    write_string  out_parent, task_id.to_s
    write_string  out_parent, serialize(parameter)

    result = read_code     in_parent
    return if result == 0
    raise Marshal.restore(read_string in_parent, encoding: 'BINARY')
  end

  def terminate
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
end
