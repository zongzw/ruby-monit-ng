require_relative '../agent'
require_relative '../../utils/constant'
require_relative '../../base/metrics'
require_relative '../../base/get/snmpget'

class FgSession < Agent

=begin
  session_agent = FgSession.new(:ip_address => ip_address,
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

    @oids = {:session_count       => "1.3.6.1.4.1.12356.101.4.1.8.0",   # session count
             :session1_rate       => "1.3.6.1.4.1.12356.101.4.1.11.0",  # session created over past 1 min
             :session10_rate      => "1.3.6.1.4.1.12356.101.4.1.12.0",  # session created over past 10 min
             :session30_rate      => "1.3.6.1.4.1.12356.101.4.1.13.0",  # session created over past 30 min
             :session60_rate      => "1.3.6.1.4.1.12356.101.4.1.14.0"   # session created over past 60 min
    }
    @result = {}
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
    @logger.info "#{self.class.name} is working ..."

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

    @logger.info "result: #{@result}"
  end


  # ibm.allenvs.fortigate.fg300c.sysstat.sessioncount/....
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]
    [:session_count, :session1_rate, :session10_rate, :session30_rate, :session60_rate].each do |key|
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

    merged = Metrics.merge(metrics_list)

    merged
  end
end