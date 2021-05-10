# DEPRECATED
# replaced by agent-mon at 2017.10.19

require_relative '../agent'
require_relative '../../base/snmp_reachable'

class QrReachable < Agent
  def initialize(option)
    super
    @snmprchs = []
    @option[:ip_address].each do |ip|
      opt = @option.clone
      opt[:ip_address] = ip
      reachable = SnmpReachable.new(opt)
      @snmprchs << reachable
    end
  end

  def work
    @logger.info("#{self.class.name} is working ...")
    @result = []
    @snmprchs.each do |item|
      item.work
      @result << item.result
      if ! item.result[:exception].empty?
        @logger.error("testing #{item.result[:option][:ip_address]} reachable: #{item.result[:exception]}")
      end
    end
  end

  # ibm.allenvs.qradar.reachable.<ipstring>
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]

    @result.each do |rlt|
      ipstring = rlt[:option][:ip_address].gsub('.', '-')

      info = {
          :sn => timestamp,
          :target => targetprefix + ".reachable",
          :instance => rlt[:option][:ip_address],
          :status => rlt[:status],
          :details => rlt[:details],
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics
    end

    merged = Metrics.merge(metrics_list)
    merged
  end
end