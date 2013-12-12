require 'optparse'
require 'yaml'

module Arsenicum
  class CLI
    include Arsenicum::Util

    autoload :Rails, 'arsenicum/cli/rails'

    attr_reader :config

    def initialize(argv)
      @config = option_parser.parse!(argv)
    end

    def boot
      Arsenicum::Procerssing::Server.start(Arsenicum::Configuration.new(config))
    end

    class OptionParser
      include Arsenicum::Util

      def initialize
        @values = {}
        @parser = ::OptionParser.new
      end

      def register(*args)
        block = args.pop
        block = block.to_proc unless block.is_a? Proc

        if block.arity == 2
          @parser.on(*args) {|v|block.call(v, @values)}
        else
          @parser.on(*args) {|v|@values.merge! normalize_hash(block.call(v))}
        end
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
        register("-c", "--config-file=YAML", -> v {YAML.load(File.read(v, encoding: "UTF-8"))})
    end
  end
end
