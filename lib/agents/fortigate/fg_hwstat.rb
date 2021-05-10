require_relative '../agent'
require_relative '../../utils/constant'
require_relative '../../base/metrics'
require_relative '../../base/get/snmpget'
require_relative '../../base/get/snmpbulk'

class FgHwStat < Agent

=begin
  hwstat_agent = FgHwStat.new(:ip_address => ip_address,
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

    @get = SnmpGet.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @bulk = SnmpBulk.new(:ip_address => @option[:ip_address], :community => @option[:community])

    @oids = {:cpu_usage         => "1.3.6.1.4.1.12356.101.4.1.3.0",     # cpu usage
             :mem_usage         => "1.3.6.1.4.1.12356.101.4.1.4.0",     # mem usage
             :mem_capacity      => "1.3.6.1.4.1.12356.101.4.1.5.0",     # mem capacity
             :disk_used         => "1.3.6.1.4.1.12356.101.4.1.6.0",     # disk used
             :disk_capacity     => "1.3.6.1.4.1.12356.101.4.1.7.0",     # disk capacity
             :low_mem_usage     => "1.3.6.1.4.1.12356.101.4.1.9.0",     # low mem usage
             :low_mem_capacity  => "1.3.6.1.4.1.12356.101.4.1.10.0",    # low mem capacity
    }

    @fgVdNumber       = ['1.3.6.1.4.1.12356.101.3.1.1.0']     # vdom number
    @fgVdEnt          = {:name      => '1.3.6.1.4.1.12356.101.3.2.1.1.2',   # vdom name
                         :cpu_usage => '1.3.6.1.4.1.12356.101.3.2.1.1.5',   # vdom cpu usage
                         :mem_usage => '1.3.6.1.4.1.12356.101.3.2.1.1.6',   # vdom mem usage
                         :session_count => '1.3.6.1.4.1.12356.101.3.2.1.1.7',   # vdom session count
                         :session_rate  => '1.3.6.1.4.1.12356.101.3.2.1.1.8'}   # vdom session rate

    @result = {}
    @vddata = {}
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :community, :cluster_name, :interval, :basetarget, :pin_code, :org_env].each do |key|
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

    @get.deal(@oids.values) do |varbind|
      @logger.debug("name: #{varbind.name}, value: #{varbind.value.to_i}")

      @oids.each_pair do |key, value|
        fgentidx = value.rindex('12356')
        surfix = value[fgentidx..-1]
        case varbind.name.to_s
          when /#{surfix}$/
            @result[key] = varbind.value.to_i
            break
        end
      end
    end

    @result[:disk_usage] = 100 * @result[:disk_used] / @result[:disk_capacity]

    vdom_number = 0
    @get.deal(@fgVdNumber) do |varbind|
      vdom_number = varbind.value.to_i
      @logger.debug("name: #{varbind.name}, value: #{varbind.value.to_i}")
    end

    @bulk.deal(@fgVdEnt.values + [0, vdom_number]) do |varbind|
      vdIndex = varbind.name.to_s.split('.')[-1]
      @vddata[vdIndex] = {} if @vddata[vdIndex].nil?

      @fgVdEnt.each_key do |item|
        oid = @fgVdEnt[item]
        varname = varbind.name.to_s
        oidsurffix = oid[oid.rindex('12356')..-1]
        if varname =~ /#{oidsurffix}/
          @vddata[vdIndex][item] = varbind.value.to_s
        end
      end
    end

    @logger.info("result: ")
    [@result, @vddata].each do |item|
      item.each_pair do |key, value|
        @logger.info "#{key}: #{value}"
      end
    end
  end

  # ibm.allenvs.fortigate.fg300c.vdomstat.vdom2.cpu_usage/sessioncount/sesrate...
  # ibm.allenvs.fortigate.fg300c.sysstat.cpu_usage/...
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]
    [:cpu_usage, :mem_usage, :disk_usage, :low_mem_usage].each do |key|
      info = {
          :sn => @option[:cluster_name] + timestamp,
          :target => targetprefix + ".#{@option[:cluster_name]}.sysstat.#{key}",
          :instance => @option[:cluster_name],
          :status => @result[key],
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics
    end

    @vddata.each_value do |vditem|
      (@fgVdEnt.keys - [:name]).each do |key|
        info = {
            :sn => @option[:cluster_name] + timestamp,
            :target => targetprefix + ".#{@option[:cluster_name]}.vdomstat.#{vditem[:name]}.#{key}",
            :instance => vditem[:name],
            :status => vditem[key],
            :timestamp => Time.now().to_i() * 1000,
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
