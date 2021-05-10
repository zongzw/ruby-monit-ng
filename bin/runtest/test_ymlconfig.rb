require_relative '../lib/utils/config'
require_relative '../lib/utils/constant'

YmlConfig.init(Constant.get_config_file2)

cfg = YmlConfig.get_config

puts cfg
