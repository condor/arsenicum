class Arsenicum::Task::ClassDispatcher < Arsenicum::Task
  include Arsenicum::Util

  attr_reader :target_class,  :target_method
  private     :target_class,  :target_method

  def initialize(id, options)
    super(id)
    (klass, method) = options[:target].split('#', 2)
    @target_class   = constantize klass
    @target_method  = target_class.instance_method method.to_sym
  end

  def run(*parameters)
    target_method.bind(target_class.new).call *parameters
  end

end
