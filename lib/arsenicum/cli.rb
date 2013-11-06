require 'optparse'
require 'yaml'

module Arsenicum
  class CLI
    autoload :Rails, 'arsenicum/cli/rails'

    attr_reader :configuration

    def initialize(argv)
      @configuration = option_parser.parse!(argv)
    end

    def boot
      Arsenicum::Server.start(configuration)
    end

    class OptionParser
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
          @parser.on(*args) {|v|@values.merge! block.call(v)}
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
        register("-c", "--config-file=YAML", -> v {YAML.load(File.read(v, encoding: "UTF-8"))}).
        register("-t", "--default-concurrency=VALUE", -> v {{default_concurrency: v.to_i}}).
        register("-q", "--queue-type=QUEUE_TYPE", -> v{{queue_type: v.to_s}}).
        register("--queue-engine-config=CONFIGKEY_VALUE", -> v, config {
          config[:engine_config] ||= {};(key, value) = v.split(':');config[:engine_config][key.to_sym] = value.to_s
        })
    end

  end
end
