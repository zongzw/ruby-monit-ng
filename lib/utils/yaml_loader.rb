require "yaml"
require_relative '../utils/logger'

class YamlLoader
  attr :file, :properties

#Takes a file and loads the properties in that file
  def initialize file
    @file = file
    @logger = MonitLogger.instance.logger
    @properties = {}
    begin
      @properties = YAML.load(File.open(@file))
    rescue
       @logger.error "#{$!} at:#{$@}"
    end
  end

  def update_yaml_with props
    open(@file, 'w') { |f|
      YAML.dump(props, f)
    }
  end
end