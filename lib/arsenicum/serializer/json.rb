class Arsenicum::Serializer::JSON
  def serialize(hash)
    JSON(hash)
  end

  def deserilize(string)
    JSON(string)
  end
end
