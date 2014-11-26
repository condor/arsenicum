require 'weakref'

class Arsenicum::Core::Worker
  include Arsenicum::Core::Commands
  include Arsenicum::Core::IOHelper

  RESULT_SUCCESS  = 0
  RESULT_FAILURE  = 0x80

  CONTROL_STOP    = 0xFF
  CONTROL_PING    = 0x30

  attr_reader :pid,
              :in_parent,       :out_parent,      :in_child,      :out_child,
              :ctrl_in_parent,  :ctrl_out_parent, :ctrl_in_child, :ctrl_out_child,
              :work_at,
              :thread,
              :active, :broker, :serializer,  :formatter, :index,
              :state
  alias_method :active?, :active

  def initialize(broker, index, worker_configuration)
    @broker     = WeakRef.new broker # avoiding circular references.
    @index      = index
    @serializer = worker_configuration[:serializer]
    @formatter  = worker_configuration[:formatter]
    @thread     = InvokerThread.new(self)
    @work_at    = :parent
    @state      = :parent
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

  def ask(task_id, *parameters)
    write_message                   out_parent, task_id,  serialize(parameters)
    loop do
      rs, = select([in_parent], [], [], 5)
      break if rs
      sleep 0.5
    end

    result, marshaled_exception = read_message  in_parent
    return if result == RESULT_SUCCESS
    raise Marshal.load(marshaled_exception)
  end

  def ask_async(success_handler, failure_handler, task_id, *parameters)
    thread.ask success_handler, failure_handler, task_id, *parameters
  end

  def stop
    thread.terminate
    return if Process.waitpid pid, Process::WNOHANG

    write_message   ctrl_out_parent, COMMAND_STOP
    Process.waitpid pid
  end

  private
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

  def active?
    case state
      when :waiting, :busy
        true
    end
  end

  def switch_state(state)
    @state  = state
    $0      = process_name
  end

  def server_loop
    begin
      rs, = select [in_child, ctrl_in_child], [], [], 0.5
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
          thread.terminate
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

  def return_to_broker
    broker.get_back_worker self
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

  class InvokerThread < Thread
    attr_accessor :task_request
    private       :task_request,  :task_request=

    def ask(success_handler, failure_handler, task_id, *parameters)
      self.task_request = [success_handler, failure_handler, task_id, parameters]
    end

    def initialize(worker)
      super do
        loop do
          begin
            next sleep(0.5) unless task_request
          rescue Interrupt
            break
          end
          (success_handler, failure_handler, task_id, parameter) = task_request

          begin
            worker.ask task_id, *parameter
            info worker, message: "Completed processing: #{task_id}"
            success_handler.call
          rescue Interrupt => e
            error worker, exception: e
            failure_handler.call e
            break
          rescue Exception => e
            error worker, exception: e
            failure_handler.call e
          ensure
            self.task_request = nil
            return_to_broker
          end
        end
      end
    end

    [:debug,  :info,  :warn,  :error, :fatal].each do |level|
      eval <<-SCRIPT, binding, __FILE__, __LINE__ + 1
        def #{level}(worker, message: nil, exception: nil)
          Arsenicum::Logger.#{level} do
            message = "[Worker #\#{worker.index}][\#{worker.work_at}][thread]\#{message}" if message
            [message, exception]
          end
        end
      SCRIPT
    end
  end
end
