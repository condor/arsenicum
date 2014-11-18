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
          command = read_code in_child
          case command
            when COMMAND_STOP
              break
            when COMMAND_TASK
              task_id_string  = read_string in_child
              task_id         = task_id_string.to_sym

              content         = read_string in_child
              parameters      = deserialize content

              task            = broker[task_id]

              begin
                task.run parameters
                write_code    out_child,  0
              rescue Exception => e
                exception_class_name = e.class.name
                message = e.message

                stacks = e.backtrace.join "\n"
                stacks.force_encoding 'BINARY'

                write_code    out_child,  1
                write_string  out_child,  exception_class_name
                write_string  out_child,  message
                write_string  out_child,  stacks
              end
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
    write_string  serialize(parameter)
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
end
