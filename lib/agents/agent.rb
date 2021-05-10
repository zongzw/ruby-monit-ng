require_relative '../utils/logger'
require_relative '../base/metrics'

class Agent

  attr_reader :option

  def initialize(option)
    @option = option
    @walk = nil
    #@logger = MonitLogger.instance.logger
    logdir = (@option[:logdir].nil?) ? "." : @option[:logdir]
    @logger = MyLogger.new(logdir + "/#{self.class.name}-#{@option[:id]}.log")
    @logger.info("agent start with option: #{@option}")
  end

  def work
    @logger.debug("Logic fatal: Common agent: did nothing ..")
  end

  def migrate

  end

  def rest
    @logger.info("#{self.class.name} sleep for #{@option[:interval]} seconds ...")
    sleep @option[:interval]
  end

  def post_grafana

  end
end
