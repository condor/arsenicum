class Arsenicum::Core::Worker
  include Arsenicum::Core::Commands

  attr_reader :pid, :in_parent, :out_parent,
              :in_child,  :out_child, :active, :broker
  alias_method :active?, :active

  def initialize(broker, worker_configuration)
    @broker = WeakRef.new broker # avoiding circular references.
  end

  def run
    (@in_parent, @out_child) = IO.pipe
    (@in_child, @out_parent) = IO.pipe

    @pid = fork do
      @active = true
      [in_parent, out_parent].each(&:close)

      begin
        loop do
          command = in_child.read(1).unpack('C').first
          case command
            when COMMAND_STOP
              next
            when COMMAND_TASK
              task_id_length = in_child.read(1).unpack('C').first
              task_id_string = in_child.read task_id_length
              task_id = task_id_string.to_sym

              length = in_child.read(4).unpack('C4').each_with_index.inject(0) do |value, byte_with_index|
                (byte, index) = byte_with_index
                addition = byte << (3 - index)
                value + addition
              end
              content = in_child.read length
              parameters = serializer.deserialize content

              task = broker[task_id]

              begin
                task.run parameters
                out_child.write "\u00"
              rescue Exception => e
                out_child.write "\u01"    # TODO implement.
              end
          end
        end
      ensure
        [in_child, out_child].each do |io|
          begin io.close rescue nil end
        end
      end
    end
    [in_child, out_child].each(&:close)
    pid
  end

  def ask(task_id, parameters)

  end

  def terminate

  end
end