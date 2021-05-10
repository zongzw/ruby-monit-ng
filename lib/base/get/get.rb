require_relative '../../../lib/utils/logger'

class Get
  def initialize(option)
    @option = option.clone
    @result = {}
    @logger = MonitLogger.instance.logger
  end

  def deal(arg)
    @result
  end
end