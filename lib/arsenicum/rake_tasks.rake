require 'arsenicum'
require 'yaml'

namespace :arsenicum do
  desc 'Create queues defined in the configuration file. Specify configuration with CONFIG=config_file_path.'
  task :create_queues do
    config_file = ENV['CONFIG'] || 'config/arsenicum.yml'
    config = Arsenicum::Configuration.new(YAML.load(File.read(config_file, encoding: 'UTF-8')))
    queue_class = config.queue_class
    raise Arsenicum::MisconfigurationError, "class #{queue_class.name} doesn't support create_queue" unless queue_class.instance_methods.include?(:create_queue_backend)

    config.create_queues.each(&:create_queue_backend)
  end
end
