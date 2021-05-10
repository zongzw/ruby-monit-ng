require_relative '../agent'
require_relative '../../utils/constant'
require_relative '../../base/metrics'
require_relative '../../base/get/snmpwalk'
require_relative '../../base/get/snmpbulk'
require_relative '../../base/get/snmpget'

class FgIfTraffic < Agent

=begin
  traffic_agent = FgIfTraffic.new(:ip_address => ip_address,
                              :community => community,
                              :serial_number => serial_number,
                              :interval => interval[item['interval']],
                              :basetarget => base_target,
                              :pin_code => marmotinfo['pin_code'],
                              :org_env => marmotinfo['org_env'])
=end

  def initialize(option)
    super
    check_option

    @walk = SnmpWalk.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @bulk = SnmpBulk.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @get = SnmpGet.new(:ip_address => @option[:ip_address], :community => @option[:community])

    @iftable_columns  = ["ifIndex", "ifDescr", "ifInOctets", "ifOutOctets", "ifSpeed"]
    @fgIntfEntVdom    = ['1.3.6.1.4.1.12356.101.7.2.1.1.1']   # mapping from interface index to vdom index
    @fgVdEntName      = ['1.3.6.1.4.1.12356.101.3.2.1.1.2']   # vdom name
    @fgVdNumber       = ['1.3.6.1.4.1.12356.101.3.1.1.0']     # vdom number

    @default_if_speed = 1000000000

    @ifdata = {}
    @if2vd = {}
    @vddata = {}
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :community, :cluster_name, :interval, :basetarget, :pin_code, :org_env].each do |key|
      unless keyset.include? key
        missing << key
      end
    end
    unless missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end

  def work
    @logger.info("#{self.class.name} is working ...")

    cur = Time.now.to_i
    @walk.deal(@iftable_columns) do |row|
      ifIndex = row[0].value.to_i
      ifDescr = row[1].value.to_s
      ifInOctets = row[2].value.to_i
      ifOutOctets = row[3].value.to_i
      ifSpeed = (row[4].value == 0) ? @default_if_speed : row[4].value.to_i
      ifInSpeed = ifOutSpeed = 0

      if ! @ifdata[ifIndex].nil?
        inOctets_increased = (ifInOctets > @ifdata[ifIndex][:ifInOctets]) ? ifInOctets - @ifdata[ifIndex][:ifInOctets] : ifInOctets - @ifdata[ifIndex][:ifInOctets] + 4294967296
        outOctets_increased = (ifOutOctets > @ifdata[ifIndex][:ifOutOctets]) ? ifOutOctets - @ifdata[ifIndex][:ifOutOctets] : ifOutOctets - @ifdata[ifIndex][:ifOutOctets] + 4294967296
        ifInSpeed = 8 * inOctets_increased / (cur - @ifdata[ifIndex][:lastUpdated])
        ifOutSpeed = 8 * outOctets_increased / (cur - @ifdata[ifIndex][:lastUpdated])
      end

      @ifdata[ifIndex] = {:ifDescr => ifDescr,
                          :ifInOctets => ifInOctets,
                          :ifOutOctets => ifOutOctets,
                          :ifInSpeed => ifInSpeed,
                          :ifOutSpeed => ifOutSpeed,
                          :ifSpeed => ifSpeed,
                          :lastUpdated => cur
      }
    end

    vdom_number = 0
    @get.deal(@fgVdNumber) do |varbind|
      vdom_number = varbind.value.to_i
    end

    @bulk.deal(@fgVdEntName + [0, vdom_number]) do |vditem|
      vdIndex = vditem.name.to_s.split('.')[-1].to_i
      @vddata[vdIndex] = vditem.value.to_s
    end

    @bulk.deal(@fgIntfEntVdom + [0, @ifdata.keys.count]) do |varbind|
      ifIndex = varbind.name.to_s.split('.')[-1].to_i
      vdIndex = varbind.value.to_i
      @if2vd[ifIndex] = vdIndex
    end

    @logger.info "result: "
    [@ifdata, @vddata, @if2vd].each do |item|
      item.each_pair do |key, value|
        @logger.info "#{key}: #{value}"
      end
    end
  end

  # ibm.allenvs.fortigate.fg300c.vdomstat.vdom1.ifInSpeed:<instances..>
  # ibm.allenvs.fortigate.fg300c.vdomstat.vdom2.ifOutSpeed:<instances..>
  def migrate
    timestamp = Time.now.to_i.to_s
    metrics_list = []

    @ifdata.each_pair do |ifIndex, record|

      portname = record[:ifDescr].gsub('.', '-')
      vdomname = @vddata[@if2vd[ifIndex]]
      next if vdomname.nil?
      [:ifInSpeed, :ifOutSpeed].each do |key|
        info = {
            :sn => @option[:cluster_name] + timestamp + "#{key.to_s}",
            :target => @option[:org_env] + "." + @option[:basetarget] +
                ".#{@option[:cluster_name]}.vdomstat.#{vdomname}.#{key}",
            :instance => portname,
            :status => record[key].to_s,
            :timestamp => record[:lastUpdated]*1000,
            :duration => 0,
            :attachments => []
        }
        metrics = Metrics.new(@option[:pin_code], info)
        metrics_list << metrics
      end
    end

    merged = Metrics.merge(metrics_list)
  end
end