module Arsenicum::Core::IOHelper
  def write_string(io, string)
    string_to_write = string.dup
    string_to_write.force_encoding 'BINARY'

    io.write [string.length].pack('N')
    io.write string
  end

  def read_string(io)
    bytes_for_length = io.read 4
    length = bytes_for_length.unpack('N').first
    return if length == 0

    io.read(length).tap{|s|s.force_encoding 'UTF-8'}
  end

  def write_code(io, integer_value)
    value = [integer_value].pack('C')
    io.write value
  end

  def read_code(io)
    string = io.read 1
    string.pack('C').first
  end
end
