require_relative '../agent'
require_relative '../../base/get/snmpget'

class QrHa < Agent
  def initialize(option)
    super
    @sysName = '1.3.6.1.2.1.1.5.0'
    @snmpget = SnmpGet.new(@option)
    @orig = ''
  end

  def work
    @logger.info("#{self.class.name} is working ...")

    @result = {}
    @snmpget.deal([@sysName]) do |vb|
      sysname = vb.value.to_s
      if @orig.empty?
        @result[:status] = 0
        @result[:details] = "initialized ha state: #{sysname}"
        @orig = sysname
      else
        if @orig == sysname
          @result[:status] = 0
          @result[:details] = "No changes: #{sysname}"
        else
          @result[:status] = 1
          @result[:details] = "Ha happens: #{@orig} -> #{sysname}"
          @orig = sysname
        end
      end
    end
  end

  # ibm.allenvs.qradar.haswitch.<ipstring>
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]
    ipstring = @option[:ip_address].gsub('.', '-')

    info = {
        :sn => timestamp,
        :target => targetprefix + ".haswitch.#{ipstring}",
        :instance => @option[:ip_address],
        :status => @result[:status],
        :details => @result[:details],
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :attachments => []
    }
    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics

    merged = Metrics.merge(metrics_list)
    merged
  end
end