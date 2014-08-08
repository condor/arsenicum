module Arsenicum
  # This module is expected to be extended only by modules
  module Backend
    def self.extended(mod)
      module_path = mod.name.split('::').map{|e|Arsenicum::Util.underscore(e)}.join('/')
      mod.instance_eval do
        autoload :Configuration,  "#{module_path}/configuration"
        autoload :Publisher,      "#{module_path}/publisher"
        autoload :Subscriber,     "#{module_path}/subscriber"
      end
    end
  end

  autoload  :Sqs,           'arsenicum/backend/sqs'
  autoload  :ActiveRecord,  'arsenicum/backend/active_record'
end
