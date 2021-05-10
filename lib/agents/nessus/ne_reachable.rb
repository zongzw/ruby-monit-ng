require_relative '../agent'
require_relative '../../base/get/snmpget'
require_relative '../../base/metrics'

class NeReachable < Agent

  def initialize(option)
    super
    check_option
    @result = {}

    @snmpget = SnmpGet.new(@option)
    @sysNameOid = '1.3.6.1.2.1.1.5.0'
    @systemName = @option[:ip_address]
    @snmpget.deal(@sysNameOid) do |varbind|
      @systemName = varbind.value.to_s
    end
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :port, :basetarget, :pin_code, :org_env, :query_timeout].each do |key|
      if !keyset.include? key
	missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end

  def work
    @logger.info("#{self.class.name} is working ...")
    @result = {}
    ip = @option[:ip_address]
    port = @option[:port]
    query_timeout = @option[:query_timeout]
    sysname = @systemName.gsub('.', '-')
    @result[:instance] = sysname
    cmd= "curl -m #{query_timeout} -k -X GET -H 'Content-Type: application/json' https://#{ip}:#{port}/server/status"
    @result[:details] = `#{cmd}`
    @result[:status] = $?.exitstatus
  end

  # ibm.allenvs.nessus.reachable
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]

    info = {
        :sn => @result[:instance] + "-" + timestamp,
        :target => targetprefix + ".reachable",
        :instance => @result[:instance],
        :status => @result[:status],
        :details => @result[:details],
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :attachments => []
    }
    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics

    merged = Metrics.merge(metrics_list)
  end
end
