require_relative '../registrar'

%W(ntp_alive).each do |item|
  require_relative "../../../lib/agents/ntp/#{item}"
end

class Ntp < Registrar
  def initialize(option)
    super
  end

  def register_agents
    obj = @option
    @logger.info "initializing ntp agents ... with configuration #{obj}"

    ip_address = obj['ip_address']
    cluster_name = obj['cluster_name']
    base_target = obj['basetarget']
    query_timeout = obj['query_timeout']
    logdir = obj[:logdir]

    obj['items'].each do |item|
      interval = @server.monit_intervals[item]
      if @server.monit_intervals[item].nil?
        interval = @server.monit_intervals['default']
      end
      option = {
          :ip_address => ip_address,
          :query_timeout => query_timeout,
          :cluster_name => cluster_name,
          :interval =>interval,
          :basetarget => base_target,
          :pin_code => @server.pin_code,
          :org_env => @server.org_env,
          :logdir => logdir,
          :id => ''
      }

      case item
        when 'ntp-alive'
          alive_agent = NtpAlive.new(option)
          @server.register(alive_agent)
        else
          @logger.error "unrecognized monitored item: #{item}"
      end
    end
  end
end
