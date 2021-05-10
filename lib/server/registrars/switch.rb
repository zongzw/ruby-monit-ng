require_relative '../registrar'

%W(sw_hwstat_c2960 sw_hwstat_nexus sw_traffic sw_policy_c2960 sw_policy_nexus sw_reachable).each do |item|
  require_relative "../../../lib/agents/switch/#{item}"
end

class Switch < Registrar
  def initialize(option)
    super
  end

  def register_agents
    obj = @option
    @logger.info "initializing switch agents ... with configuration #{obj}"

    ip_address = obj['ip_address']
    community = obj['community']
    base_target = obj['basetarget']
    username = obj['username']
    password = obj['password']
    exvlan = obj['excludedvlan']
    tops = obj['tops']

    obj['ip_address'].each_with_index do |ip, idx|
      obj['items'].each do |item|
        interval = @server.monit_intervals[item]
        if @server.monit_intervals[item].nil?
          interval = @server.monit_intervals['default']
        end
        option = {
            :ip_address => ip,
            :community => community,
            :interval => interval,
            :basetarget => base_target,
            :pin_code => @server.pin_code,
            :org_env => @server.org_env,
            :username => username,
            :password => password,
            :exvlan => exvlan,
            :tops => tops,
            :id => ip,
            :logdir => obj[:logdir]
        }

        case item
          when 'hwstat-c2960'
            hwstat_agent = SwHwstatC2960.new(option)
            @server.register(hwstat_agent)
          when 'hwstat-nexus'
            hwstat_agent = SwHwstatNexus.new(option)
            @server.register(hwstat_agent)
          when 'traffic'
            traffic_agent = SwTraffic.new(option)
            @server.register(traffic_agent)
          when 'ios-config-update'
            policy_agent = SwPolicyC2960.new(option)
            @server.register(policy_agent)
          when 'nexus-config-update'
            policy_agent = SwPolicyNexus.new(option)
            @server.register(policy_agent)
          #when 'reachable'
          #  reachable_agent = SwReachable.new(option)
          #  @server.register(reachable_agent)
          else
            @logger.error "unrecognized monitored item: #{item}"
        end
      end
    end
  end
end
