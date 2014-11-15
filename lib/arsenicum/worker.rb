class Arsenicum::Worker
  include Arsenicum::Commands

  attr_reader :pid, :in_parent, :out_parent,
              :in_child,  :out_child

  def run
    (@in_parent, @out_child) = IO.pipe
    (@in_child, @out_parent) = IO.pipe

    @pid = fork do
      [in_parent, out_parent].each(&:close)

      begin
        loop do
          command = in_child.read(1).unpack('C').first
          case command
            when COMMAND_STOP
              next
            when COMMAND_TASK
              length = in_child.read(4).unpack('C').each_with_index.inject(0) do |value, byte_with_index|
                (byte, index) = byte_with_index
                addition = byte << (3 - index)
                value + addition
              end
              content = in_child.read length
              value = serializer.deserialize content
              execute value
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

  def ask(params)

  end

  def terminate

  end
end