class Arsenicum::Task::ClassDispatcher < Arsenicum::Task
  attr_reader :target_class,  :target_method
  private     :target_class,  :target_method

  def initialize(id, options)
    super(id)
    @target_class   = options.delete :type
    @target_method  = options.delete :target
  end

  def run(*parameters)
    target_class.new.__send__ target_method, *parameters
  end

end
