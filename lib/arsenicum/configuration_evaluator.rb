require 'yaml'
require 'optparse'

class Arsenicum::ConfigurationEvaluator
  attr_reader :option_parser

  def initialize(mappings)
    mappings.each do |long_name, options|

    end
  end

  def from_file(file)
    File.open(file, 'r:UTF-8') do |f|
      YAML.load f
    end
  end

  def from_command_line(args)

  end
end
