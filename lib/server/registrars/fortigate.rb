require_relative '../registrar'

%W(fg_ha fg_hwstat fg_iftraffic fg_session
   fg_policy fg_policy2 fg_config fg_reachable fg_reachable2
   fg_sslvpn).each do |item|
  require_relative "../../../lib/agents/fortigate/#{item}"
end

class Fortigate < Registrar
  def initialize(option)
    super
  end

  def register_agents
    obj = @option
    @logger.info "fortigate agent initializing ... #{obj}"

    ip_address = obj['ip_address']
    community = obj['community']
    cluster_name = obj['cluster_name']
    base_target = obj['basetarget']
    username = obj['username']
    password = obj['password']
    port = obj['port']
    tops = obj['tops']
    logdir = obj[:logdir]

    ip_address.each_with_index do |ip, idx|
      obj['items'].each do |item|
        interval = @server.monit_intervals[item]
        if @server.monit_intervals[item].nil?
          interval = @server.monit_intervals['default']
        end
        option = {
            :ip_address => ip,
            :community => community,
            :cluster_name => cluster_name[idx],
            :interval =>interval,
            :basetarget => base_target,
            :pin_code => @server.pin_code,
            :org_env => @server.org_env,
            :username => username,
            :password => password,
            :port => port,
            :tops => tops,
            :logdir => logdir,
            :id => ip
        }

        case item
          when 'ha'
            #@logger.warn "not implemented: #{item}"
            fg_agent = FgHa.new(option)
            @server.register(fg_agent)
          when 'traffic'
            traffic_agent = FgIfTraffic.new(option)
            @server.register(traffic_agent)
          when 'hwstat'
            hwstat_agent = FgHwStat.new(option)
            @server.register(hwstat_agent)
          when 'session'
            session_agent = FgSession.new(option)
            @server.register(session_agent)
          #when 'policy'
          #  policy_agent = FgPolicy.new(option)
          #  @server.register(policy_agent)
          #when 'policy2'
          #  policy_agent2 = FgPolicy2.new(option)
          #  @server.register(policy_agent2)
          when 'config'
            config_agent = FgConfig.new(option)
            @server.register(config_agent)
          #when 'reachable'
          #  reachable_agent = FgReachable.new(option)
          #  @server.register(reachable_agent)
          #when 'reachable'
          #  reachable_agent = FgReachable2.new(option)
          #  @server.register(reachable_agent)
          when 'sslvpn'
            sslvpn_agent = FgSslVpn.new(option)
            @server.register(sslvpn_agent)
          else
            @logger.error "unrecognized monitored item: #{item}"
        end
      end
    end
  end
end