require 'multi_json'

class Arsenicum::Serializer::JSON
  def serialize(hash)
    MultiJson.encode(hash)
  end

  def deserialize(string)
    MultiJson.decode(string)
  end
end
