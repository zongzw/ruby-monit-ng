require_relative '../registrar'

%W(ne_reachable ne_hwstat).each do |item|
  require_relative "../../../lib/agents/nessus/#{item}"
end

class Nessus < Registrar
  def initialize(option)
    super
  end

  def register_agents
    obj = @option
    @logger.info "register nessus agents with configuration: #{obj}"
    ip_address = obj['ip_address']
    base_target = obj['basetarget']
    community = obj['community']
    snmp_port = obj['snmpport']
    port = obj['port']
    query_timeout = obj['query_timeout']

    ip_address.each do |ip|
      raise ArgumentError, "Missing argument items list." if obj['items'].nil?
      obj['items'].each do |item|
        interval = @server.monit_intervals[item]
        if @server.monit_intervals[item].nil?
          interval = @server.monit_intervals['default']
        end
        option = {
            :community => community,
            :snmpport => snmp_port,
            :basetarget => base_target,
            :pin_code => @server.pin_code,
            :org_env => @server.org_env,
            :interval => interval,
            :logdir => obj[:logdir],
            :disk_check => obj['disk_check'],
	    :ip_address => ip,
	    :port => port,
	    :id => ip,
	    :query_timeout => query_timeout
        }
        case item
          when 'reachable'
            reachable_agent = NeReachable.new(option.clone)
            @server.register(reachable_agent)
          when 'hwstat'
	    hwstat_agent = NeHwStat.new(option)
            @server.register(hwstat_agent)
          else
            @logger.warn("found unmonitored item: #{item}")
        end
      end
    end
  end
end
