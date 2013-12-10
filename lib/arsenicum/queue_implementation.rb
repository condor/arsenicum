module Arsenicum
  # This module is expected to be extended only by modules
  module QueueImplementation
    def self.extended(mod)
      module_path = mod.name.split('::').map{|e|Arsenicum::Util.underscore(e)}.join('/')
      mod.instance_eval do
        autoload :Queue, "#{module_path}/queue"
        autoload :Configuration, "#{module_path}/configuration"
      end
    end
  end
end