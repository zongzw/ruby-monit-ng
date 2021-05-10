require_relative '../agent'
require_relative '../../utils/constant'
require_relative '../../base/metrics'
require_relative '../../base/get/snmpwalk'

class FgHa < Agent

=begin
  ha_agent = FgHa.new(:ip_address => ip_address,
                              :community => community,
                              :serial_number => serial_number,
                              :interval => interval[item['interval']],
                              :basetarget => base_target,
                              :cluster_name => 'sdf',
                              :pin_code => marmotinfo['pin_code'],
                              :org_env => marmotinfo['org_env'])
=end

  def initialize(option)
    super
    check_option
    @walk = SnmpWalk.new(:ip_address => @option[:ip_address], :community => @option[:community])

    @fgHaStatsIndex  = ['1.3.6.1.4.1.12356.101.13.2.1.1.1']     #An index value that uniquely identifies an unit in the HA cluster
    @fgHaStatsSerial = ['1.3.6.1.4.1.12356.101.13.2.1.1.2']     #Serial number of the HA cluster member

    @fgHaOids = @fgHaStatsIndex + @fgHaStatsSerial

    @result = {}
    @haResult = {}
    @origin = '' #original HA master
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

    diff = ''
    @walk.deal(@fgHaOids) do |row|
      haIndex = row[0].value.to_i
      haSerials = row[1].value.to_s
      @haResult[haIndex] = haSerials
    end
    updated = @haResult[1] #updated HA master

    if @origin.eql? ''
      diff = ''
      @origin = updated
    else
      if ! @origin.eql? updated
        diff = "HA switch happen: #{@origin} => #{updated}"
        @origin = updated
      end
    end

    @result = diff

    @logger.info "ha master diff result: #{@result}"
    @logger.info "ha status result: #{@haResult}"
  end


  # ibm.allenvs.fortigate.fg300c.haswitch
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]

    info = {
        :sn => @option[:cluster_name] + timestamp,
        :target => targetprefix + ".#{@option[:cluster_name]}.haswitch",
        :instance => @option[:cluster_name],
        :status => @result.eql?('') ? 0 : 1,
        :details => @result,
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :attachments => []
    }
    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics

    info = {
        :sn => @option[:cluster_name] + timestamp,
        :target => targetprefix + ".#{@option[:cluster_name]}.hamember",
        :instance => @option[:cluster_name],
        :status => @haResult.size,
        :details => @haResult.values,
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