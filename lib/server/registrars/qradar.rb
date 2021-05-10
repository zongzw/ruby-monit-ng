require_relative '../registrar'

%W(qr_reachable qr_ha qr_hwstat qr_eps qr_alert qr_web qr_syslog qr_qrate).each do |item|
  require_relative "../../../lib/agents/qradar/#{item}"
end

class Qradar < Registrar
  def initialize(option)
    super
  end

  def register_agents
    obj = @option
    @logger.info "register qradar agents with configuration: #{obj}"

    iplist = []
    raise ArgumentError, "Missing argument reachable list." if obj['reachable'].nil?
    obj['reachable'].each do |listitem|
      raise ArgumentError, "Missing argument #{listitem}" if obj[listitem].nil?
      iplist = iplist - obj[listitem] + obj[listitem]

      interval = @server.monit_intervals[listitem]
      if @server.monit_intervals[listitem].nil?
        interval = @server.monit_intervals['default']
      end
      option = {
          :community => obj['community'],
          :snmpport => obj['snmpport'],
          :basetarget => obj['basetarget'],
          :pin_code => @server.pin_code,
          :org_env => @server.org_env,
          :interval => interval,
          :logdir => obj[:logdir],
          :disk_check => obj['disk_check']
      }
      case listitem
        when 'qrha'
          obj[listitem].each do |ip|
            option[:ip_address] = ip
            option[:id] = ip
            qrha_agent = QrHa.new(option.clone)
            @server.register(qrha_agent)
          end
        when 'hwstat'
          obj[listitem].each do |ip|
            option[:ip_address] = ip
            option[:id] = ip
            qrhwstat_agent = QrHwStat.new(option.clone)
            @server.register(qrhwstat_agent)
          end
        else
          @logger.warn("found unmonitored item: #{listitem}")
      end
    end

    # register reachable agents
    interval = @server.monit_intervals['reachable']
    if @server.monit_intervals['reachable'].nil?
      interval = @server.monit_intervals['default']
    end
    option = {
        :ip_address => iplist,
        :community => obj['community'],
        :snmpport => obj['snmpport'],
        :basetarget => obj['basetarget'],
        :pin_code => @server.pin_code,
        :org_env => @server.org_env,
        :interval => interval,
        :id => '',
        :logdir => obj[:logdir]
    }
    qradar_agent = QrReachable.new(option)
    @server.register(qradar_agent)

    # register eps agents
    if obj['qreps'] == true
      @logger.info("register eps agents...")
      interval = @server.monit_intervals['qreps']
      if @server.monit_intervals['qreps'].nil?
        interval = @server.monit_intervals['default']
      end
      option = {
          :community => obj['community'],
          :snmpport => obj['snmpport'],
          :basetarget => obj['basetarget'],
          :pin_code => @server.pin_code,
          :org_env => @server.org_env,
          :interval => interval,
          :id => '',
          :logdir => obj[:logdir]
      }
      epsagent = QrEps.new(option)
      @server.register(epsagent)
    end

    # register alert agents
    if obj['qralert'] == true
      @logger.info("register alert agents...")
      interval = @server.monit_intervals['qralert']
      if @server.monit_intervals['qralert'].nil?
        interval = @server.monit_intervals['default']
      end
      option = {
          :basetarget => obj['basetarget'],
          :pin_code => @server.pin_code,
          :org_env => @server.org_env,
          :interval => interval,
          :logdir => obj[:logdir],
          :tcp_port => obj['tcp_port'],
          :rate_interval => obj['alert_rate_interval']
      }
      alertagent = QrAlert.new(option)
      @server.register(alertagent)
    end

    if obj['qrweb'] == true
      @logger.info("register qrweb agents...")
      interval = @server.monit_intervals['qrweb']
      if @server.monit_intervals['qrweb'].nil?
        interval = @server.monit_intervals['default']
      end
      option = {
          :basetarget => obj['basetarget'],
          :pin_code => @server.pin_code,
          :org_env => @server.org_env,
          :interval => interval,
          :logdir => obj[:logdir],
          :weburl => obj['weburl'],
      }
      webagent = QrWeb.new(option)
      @server.register(webagent)
    end

    @logger.info("register qrsyslog agents...")
    interval = @server.monit_intervals['qrsyslog']
    if @server.monit_intervals['qrsyslog'].nil?
        interval = @server.monit_intervals['default']
    end
    option = {
        :basetarget => obj['basetarget'],
        :pin_code => @server.pin_code,
        :org_env => @server.org_env,
        :interval => interval,
        :logdir => obj[:logdir],
    }
    webagent = QrSyslog.new(option)
    @server.register(webagent)

    @logger.info("register query rate agents...")
    interval = @server.monit_intervals['qrqrate']
    if @server.monit_intervals['qrqrate'].nil?
        interval = @server.monit_intervals['default']
    end
    option = {
        :basetarget => obj['basetarget'],
        :pin_code => @server.pin_code,
        :org_env => @server.org_env,
        :interval => interval,
        :logdir => obj[:logdir],
        :tcp_port => obj['qrate_tcp_port']
    }
    webagent = QrQrate.new(option)
    @server.register(webagent)
  end
end
