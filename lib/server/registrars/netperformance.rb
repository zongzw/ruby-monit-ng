require_relative '../registrar'

%W(netperf_intercloud).each do |item|
  require_relative "../../../lib/agents/netperformance/#{item}"
end

class Netperformance < Registrar
  def initialize(option)
    super
  end

  def register_agents
    obj = @option
    @logger.info "Initializing Network Performance agents ... with configuration #{obj}"

    hosts = obj['hosts']
    username = obj['username']
    password = obj['password']
    basetarget = obj['basetarget']
    logdir = obj[:logdir]
    iperf_port = obj['iperf_port']
    iperf_time = obj['iperf_time']
    monit_time = obj['monit_time']

    id = ''
    hosts.each do |host|
      id += host['cluster_name'].to_s
    end


    obj['items'].each do |item|
      interval = @server.monit_intervals[item]
      if @server.monit_intervals[item].nil?
        interval = @server.monit_intervals['default']
      end

      option = {
          :hosts => hosts,
          :username => username,
          :password => password,
          :iperf_port => iperf_port,
          :iperf_time => iperf_time,
          :monit_time => monit_time,
          :basetarget => basetarget,
          :pin_code => @server.pin_code,
          :org_env => @server.org_env,
          :logdir => logdir,
          :interval =>interval,
          :id => id
      }

      case item
        when 'netperf_intercloud'
          agent = NetPerfInterCloud.new(option)
          @server.register(agent)
        else
          @logger.error "unrecognized network performance monitoring item: #{item}"
      end
    end
  end
end
