require 'arsenicum'
require 'yaml'

namespace :arsenicum do
  desc 'Create queues defined in the configuration file. Specify configuration with CONFIG=config_file_path.'
  task :create_queues do
    config_file = ENV['CONFIG'] || 'config/arsenicum.yml'
    yaml = YAML.load(Erubis::Eruby.new(File.read(config_file, encoding: 'UTF-8')).result)
    config_values =
      if ENV['CONFIG_KEY']
        ENV['CONFIG_KEY'].split('.').inject(yaml) do |values, key|
          values[key]
        end
      else
        yaml
      end

    config = Arsenicum::Configuration.new(config_values)
    queue_class = config.queue_class
    raise Arsenicum::MisconfigurationError, "class #{queue_class.name} doesn't support create_queue" unless queue_class.instance_methods.include?(:create_queue_backend)

    config.create_queues.each(&:create_queue_backend)
  end
end
