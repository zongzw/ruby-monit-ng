require_relative 'agent-engine'
require_relative '../utils/logger'
require_relative '../agents/agent'

class Registrar
  def initialize(option)
    #@logger = MonitLogger.instance.logger
    @option = option

    logpath = (@option[:logdir].nil?) ? '.' : @option[:logdir]
    @logger = MyLogger.new(logpath + "/register.log", "weekly")
    @server = server = AgentsServer.instance
  end

  def register_agents
  end
end
