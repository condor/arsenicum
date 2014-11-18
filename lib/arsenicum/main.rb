module Arsenicum
  module Main
    def run(arguments = [])
      configuration = configure(arguments)
    end

    def configure(arguments = [])
      #TODO return configuration.
    end

    module_function :run, :configure
  end
end
