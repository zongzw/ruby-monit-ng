require_relative '../agent'
require_relative '../../base/get/snmptrap'
require_relative '../../base/get/snmpget'
require_relative '../../../data/qradar-hostname-ip-mapping'

class QrEps < Agent

  #attr_reader :update
  include QRADARHOSTNAMEIPMAPPING

  def initialize(option)
    super
    check_option

    @trapget = SnmpTrap.new(@option)
    @sysNameOid = '1.3.6.1.2.1.1.5.0'

    @lock = Mutex.new

    @update = []
    @trapget.deal do |trap|
      data = {
          :timestamp => trap.sys_up_time.to_i,
          :epsoid => trap.trap_oid.to_s,
          :epsvalue => trap.varbind_list[2].value.to_s,
          :sourceip => trap.source_ip.to_s
      }

      @lock.lock
      @update << data
      @lock.unlock
    end
  end

  def work
    @logger.info("#{self.class.name} is working...")
    @result = {}

    @lock.lock
    @update.each do |data|
      rlt = {}

      m = /host:\s*(.*),\s*rate:\s*([0-9\.]+)/.match(data[:epsvalue])
      if m.nil?
        rlt[:status] = -2
        rlt[:details] = "#{data[:epsvalue]} cannot match: host: (.*), rate: ([0-9\.]+)"
        next
      end

      rlt[:status] = m[2].to_f
      rlt[:details] = "#{data}"

      # begin
      #   option = @option.clone
      #   option[:ip_address] = m[1]
      #   snmpget = SnmpGet.new(option)
      #   snmpget.deal(@sysNameOid) do |varbind|
      #     rlt[:instance] = varbind.value.to_s
      #   end
      # rescue => e
      #   rlt[:instance] = m[1]
      #   @logger.warn("failed to get host name for #{m[1]}, use ip instead.")
      #   @logger.warn("#{e.inspect}, #{e.backtrace}")
      # end
      rlt[:instance] = (HostIpMapping[m[1]].nil?) ? m[1] : HostIpMapping[m[1]]

      @result[rlt[:instance]] = rlt
    end

    @update = []
    @lock.unlock

    #if @result.empty?
    #  @result['canary']  = {:details => "no data available from eps hosts.", :status => -1, :instance => 'canary'}
    #end
  end

  # ibm.allenvs.qradar.eps: instances
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]
    all_envs = HostIpMapping.values.uniq

    @result.values.each do |rlt|
      all_envs -= [rlt[:instance]]
      info = {
          :sn => timestamp,
          :target => targetprefix + ".eps." + rlt[:instance],
          :instance => rlt[:instance],
          :status => rlt[:status],
          :details => rlt[:details],
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics
    end

    status = 1
    details = 'All EPSes are working fine.'
    if !all_envs.empty?
      status = -1
      details = "EPS:#{all_envs} down."
    end

    info = {
        :sn => timestamp,
        :target => targetprefix + ".EPS_status",
        :instance => all_envs,
        :status => status,
        :details => details,
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :attachments => []
    }
    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics

    merged = Metrics.merge(metrics_list)
    merged
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:basetarget, :pin_code, :org_env, :community, :interval].each do |key|
      if !keyset.include? key
        missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end
end
