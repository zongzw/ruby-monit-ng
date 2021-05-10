require_relative '../registrar'

%W(fg_bandwidth).each do |item|
  require_relative "../../../lib/agents/bandwidth/#{item}"
end

class Bandwidth < Registrar
  def initialize(option)
    super
  end

  def register_agents
    obj = @option
    @logger.info "Initializing bandwidth agents ... with configuration #{obj}"

    interfaces = obj['interfaces']
    basetarget = obj['basetarget']
    sample_interval = obj['sample_interval']
    short_term = obj['short_term']
    long_term = obj['long_term']
    logdir = obj[:logdir]

    option = {
        :basetarget => basetarget,
        :interval => sample_interval,
        :short_term => short_term,
        :long_term => long_term,
        :pin_code => @server.pin_code,
        :org_env => @server.org_env,
        :logdir => logdir
    }

    interfaces.each do |item|
      option[:ip_address] = item['ip_address']
      option[:interface_name] = item['interface_name']
      option[:bandwidth_in_Mbps] = item['bandwidth_in_Mbps']
      option[:cluster_name] = item['cluster_name']
      option[:id] = item['ip_address']
      case item['device']
        when 'fortigate'
          option[:community] = item['community']
          fg_bandwidth_agent = FgBandwidth.new(option.clone)
          @server.register(fg_bandwidth_agent)
        else
          @logger.error "Unrecognized bandwidth monitoring item: #{item}"
      end
    end
  end
end
