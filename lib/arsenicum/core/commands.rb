module Arsenicum::Core::Commands
  COMMAND_STOP = 0xff
  COMMAND_TASK = 0x10

  class << self
    private
    def code_to_string(code)
      [code].pack('C')
    end
  end

  COMMAND_STRING_STOP = code_to_string(COMMAND_STOP)
  COMMAND_STRING_TASK = code_to_string(COMMAND_TASK)

end
