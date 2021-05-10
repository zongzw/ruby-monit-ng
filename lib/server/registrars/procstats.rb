require_relative '../registrar'

%W(proc_stat).each do |item|
  require_relative "../../../lib/agents/procstats/#{item}"
end

class Procstats < Registrar
  def initialize(option)
    super
  end


  def register_agents
    obj = @option
    @logger.info("register procstats agent with configuration #{obj}")

    ip_address = obj['ip_address']
    basetarget = obj['basetarget']
    username = obj['username']
    password = obj['password']
    processes = obj['processes']
    interval = obj['interval']
    logdir = obj[:logdir]

    options = {
        :ip_address => ip_address,
        :basetarget => basetarget,
        :username => username,
        :password => password,
        :interval => interval,
        :pin_code => @server.pin_code,
        :org_env => @server.org_env,
        :id => ip_address,
        :logdir => logdir
    }

    processes.each do |item|
      options[:name] = item['name']
      options[:matches] = item['matches']
      process = ProcStat.new(options)
      @server.register(process)
    end

  end
end