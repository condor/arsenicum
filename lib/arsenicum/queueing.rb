module Arsenicum
  module Queueing
    autoload :Request,    'arsenicum/queueing/request'
    autoload :Serializer, 'arsenicum/queueing/serializer'
    autoload :PostOffice, 'arsenicum/queueing/post_office'
  end
end