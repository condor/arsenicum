class Arsenicum::Core::Task
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def run(*parameters)
    # Originally do nothing. This will be overridden in the derived classes.
  end
end