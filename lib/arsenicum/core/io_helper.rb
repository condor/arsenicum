module Arsenicum::Core::IOHelper
  TYPE_INT    = "\xa0".force_encoding(Encoding::BINARY).freeze
  TYPE_STRING = "\xfc".force_encoding(Encoding::BINARY).freeze

  def write_message(io, *items)
    buffer = StringIO.new
    buffer.set_encoding Encoding::BINARY
    buffer.seek 4# length of integer.

    items.each do |item|
      case item
        when Fixnum
          buffer.write  TYPE_INT
          buffer.write [item].pack('N')
        when String, Symbol
          item = item.to_s.force_encoding Encoding::BINARY
          buffer.write  TYPE_STRING
          length = item.length
          buffer.write int2bin(length)
          buffer.write  item
      end
    end
    buffer.seek   0
    buffer.write  int2bin(buffer.length - 4)

    io.write      buffer.string
  end

  def read_message(io, encoding: Encoding::UTF_8)
    bytes_for_length = read_from io, 4
    length = bin2int(bytes_for_length)
    return [] if length == 0

    bytes = read_from(io, length)
    ptr = 0

    result = []
    while ptr < bytes.length
      type_byte = bytes[ptr]
      ptr += 1
      case type_byte
        when TYPE_INT
          result << bin2int(bytes[ptr...ptr + 4])
          ptr += 4
        when TYPE_STRING
          length = bin2int(bytes[ptr...ptr + 4])
          ptr += 4
          next result << '' if length == 0
          result << bytes[ptr...ptr + length].force_encoding(encoding)
          ptr += length
      end
    end
    result
  end

  private
  def read_from(io, length)
    bytes = io.read length
    raise Arsenicum::IO::EOFException unless bytes
    bytes.force_encoding Encoding::BINARY
  end

  def int2bin(number)
    [number].pack('N')
  end

  def bin2int(bytes)
    bytes.unpack('N').first
  end

end
