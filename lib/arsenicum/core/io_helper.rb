module Arsenicum::Core::IOHelper
  def write_string(io, string)
    string_to_write = string.dup
    string_to_write.force_encoding 'BINARY'

    io.write [string.length].pack('N')
    io.write string
  end

  def read_string(io, encoding: 'UTF-8')
    bytes_for_length = read_from io, 4
    length = bytes_for_length.unpack('N').first
    return if length == 0

    read_from(io, length).tap{|s|s.force_encoding encoding}
  end

  def write_code(io, integer_value)
    value = [integer_value].pack('C')
    io.write value
  end

  def read_code(io)
    string = read_from io, 1
    string.unpack('C').first
  end

  private
  def read_from(io, length)
    bytes = io.read length
    raise Arsenicum::IO::EOFException unless bytes
    bytes
  end
end
