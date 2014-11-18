class Arsenicum::Core::ClassDispatcherTask < Arsenicum::Core::Task
  attr_reader :target_class,  :target_method
  private     :target_class,  :target_method

  def initialize(id, target_class, target_method)
    super(id)
    @target_class   = target_class
    @target_method  = target_method
  end

  def run(parameters)
    target_class.new.__send__ target_method, *parameters
  end

end