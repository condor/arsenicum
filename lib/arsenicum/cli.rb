require 'optparse'
require 'yaml'

module Arsenicum
  class CLI
    attr_reader :configuration

    def initialize(argv)
      @configuration = option_parser.parse!(argv)
    end

    def boot
      Server.start(configuration)
    end

    class OptionParser
      def initialize
        @values = {}
        @parser = ::OptionParser.new
      end

      def register(*args)
        block = args.pop
        block = block.to_proc unless block.is_a? Proc

        @parser.on(*args) {|v|@values.merge! block.call(v)}
        self
      end

      def parse!(argv)
        @parser.parse! argv
        @values
      end
    end

    private
    def option_parser
      OptionParser.new.
        register("-c", "--config-file=YAML", -> v {YAML.load(File.read(v, "r:UTF-8"))}).
        register("-t", "--default-concurrency=VALUE", -> v {{default_concurrency: v.to_i}})
    end

  end
end
