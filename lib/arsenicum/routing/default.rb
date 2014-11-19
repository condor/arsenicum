class Arsenicum::Routing::Default < Arsenicum::Routing::Router
  def route(message)
    return [:default, message]
  end
end
