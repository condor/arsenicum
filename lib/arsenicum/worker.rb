require 'weakref'
require 'celluloid'

class Arsenicum::Worker
  include Celluloid
  finalizer   :stop
  attr_reader :state, :handlers

  def initialize(queue)
    @queue    = WeakRef.new queue
    @handlers = {}
    run
  end

  def request(task, success_handler, failure_handler)
    task_data = serialize task
    out_parent.write task_data
    rs, = select [in_parent]
    result = deserialize rs.first.readpartial(10240)

    if result.has_exception?
      failure_handler.call result.exception, task
    else
      success_handler.call task
    end
  end

  def stop
    return unless child_process_alive?

    write_message   ctrl_out_parent, COMMAND_STOP
    Process.waitpid pid
  end

  private
  def child_process_alive?
    !Process.waitpid(pid, Process::WNOHANG)
  end

  def run
    (@in_parent, @out_child)            = open_binary_pipes
    (@in_child, @out_parent)            = open_binary_pipes
    (@ctrl_in_parent, @ctrl_out_child)  = open_binary_pipes
    (@ctrl_in_child,  @ctrl_out_parent) = open_binary_pipes

    @pid = fork &method(:run_in_child)
    return unless @pid

    @active = true
    [in_child, out_child, ctrl_in_child, ctrl_out_child].each(&:close)
    pid
  end

  def open_binary_pipes
    IO.pipe.each do |io|
      io.set_encoding 'BINARY'
    end.tap do |pipes|
      pipes.last.sync = true
    end
  end

  def run_in_child
    switch_state  :waiting
    [in_parent, out_parent, ctrl_in_parent, ctrl_out_parent].each(&:close)
    @work_at      = :child

    hook_signal

    begin
      loop do
        server_loop
        break unless state == :waiting
      end
    ensure
      [in_child, out_child, ctrl_in_child, ctrl_out_child].each do |io|
        begin io.close rescue nil end
      end
    end
  end

  def server_loop
    begin
      rs, = select [in_child, ctrl_in_child], [], []
      return unless rs
    rescue Interrupt
      switch_state :interrupted
      return
    end

    rs.first == in_child ? handle_request : handle_control
  end

  def handle_request
    switch_state  :busy
    begin
      task_id_string, content = read_message in_child, encoding: Encoding::UTF_8
    rescue Arsenicum::IO::EOFException
      # Interrupted request: No required GC.
      return
    end

    task_id         = task_id_string.to_sym
    task            = broker[task_id]
    parameters      = content.length == 0 ? [] : deserialize(content)

    begin
      info message: "Task[#{task_id}] start"
      info message: "Parameters: #{parameters.inspect}"

      task.run      *parameters
      info message: 'Task success'
      write_message out_child,  RESULT_SUCCESS
    rescue Exception => e
      error message: "Task #{task_id} Failed", exception: e
      write_message out_child,  RESULT_FAILURE, Marshal.dump(e)
    end
  ensure
    switch_state  :waiting
  end

  def handle_control
    begin
      control, = read_message ctrl_in_child
      case control
        when CONTROL_STOP
          info message: '[Control]Received stop command.'
          switch_state  :stopped
      end
    end
  end

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

  def process_name
    "arsenicum[Worker ##{index}] - #{state}"
  end

  [:debug,  :info,  :warn,  :error, :fatal].each do |level|
    eval <<-SCRIPT, binding, __FILE__, __LINE__ + 1
    def #{level}(message: nil, exception: nil)
      Arsenicum::Logger.#{level} do
        message = "[Worker #\#{index}][\#{work_at}]\#{message}" if message
        [message, exception]
      end
    end
    SCRIPT
  end

  def switch_state new_state
    @state = new_state
  end

  def log_message_for(message)
    "[Worker ##{object_id}]#{message}"
  end

  def hook_signal
    [:USR1, :USR2, ].each do |sig|
      Signal.trap sig do
        exit 1
      end
    end
  end
end
