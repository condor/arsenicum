require 'arsenicum'
require 'rails'

module Arsenicum
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'arsenicum/rake_tasks.rake'
    end
  end
end
