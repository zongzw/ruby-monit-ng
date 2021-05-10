require_relative '../utils/yaml_loader'

class YmlConfig
  class << self
    def init(config_file)
      @config_file = config_file
      @config = YamlLoader.new(@config_file).properties
      @dbm = nil
      @dbm_log = nil
      return @config
    end

    def get_config
      @config
    end

    def reload_config
      @config = YamlLoader.new(@config_file).properties
    end
  end
end