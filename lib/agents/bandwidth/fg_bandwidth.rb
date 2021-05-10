# Fortigate interface bandwidth utilization
require_relative '../agent'
require_relative '../../utils/constant'
require_relative '../../base/metrics'
require_relative '../../base/get/snmpwalk'
require_relative '../../base/get/snmpbulk'
require_relative '../../base/get/snmpget'


class FgBandwidth < Agent

  def initialize(option)
    super
    check_option

    @ifDescr = ['1.3.6.1.2.1.2.2.1.2']   # list of interface names
    @ifInOctets = "1.3.6.1.2.1.2.2.1.10" # list of interface in Octets
    @ifOutOctets = "1.3.6.1.2.1.2.2.1.16" # list of interface out Octets

    @walk = SnmpWalk.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @get = SnmpGet.new(:ip_address => @option[:ip_address], :community => @option[:community])

    @iftable_columns  = ["ifIndex", "ifDescr"]

    @output_target2instance = {
        :ifBits => %W(inBits outBits),
        :avgSpeedShortTerm => %W(inAvgspeed_in_#{@option[:short_term]}seconds outAvgspeed_in_#{@option[:short_term]}seconds),
        :avgSpeedLongTerm => %W(inAvgspeed_in_#{@option[:long_term]}seconds outAvgspeed_in_#{@option[:long_term]}seconds),
        :BWUtilizationShortTerm => %W(inBWUtil_in_#{@option[:short_term]}seconds outBWUtil_in_#{@option[:short_term]}seconds),
        :BWUtilizationLongTerm => %W(inBWUtil_in_#{@option[:long_term]}seconds outBWUtil_in_#{@option[:long_term]}seconds)
    }

    @ifname2oids = {}
    @ifbandwidth = {}

    get_ifname2oids
    init_result

    #reason for +1: e.g. short_term = 60s, interval = 10s. will keep 60/10 + 1 = 7 data,
    # so that the interval between the 7th and 1st data is 60s
    @short_term_len = @option[:short_term] / @option[:interval] + 1
    @long_term_len = @option[:long_term] / @option[:interval] + 1
  end


  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :interface_name, :bandwidth_in_Mbps, :cluster_name, :basetarget, :pin_code,
     :org_env, :interval, :short_term, :long_term].each do |key|
      if !keyset.include? key
        missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end

  #Given the names of interfaces that need to be monitored, get the oids of their in and out Octets
  def get_ifname2oids
    interface_name = @option[:interface_name].clone
    interface_bandwidth = @option[:bandwidth_in_Mbps].clone
    @walk.deal(@iftable_columns) do |row|
      next if interface_name.size == 0
      ifIndex = row[0].value.to_i
      ifDescr = row[1].value.to_s

      interface_name.each_with_index do |name,idx|
        if name.to_s == ifDescr
          @ifname2oids[name] = {
              :ifInOctetsOid  => @ifInOctets + '.' + ifIndex.to_s,
              :ifOutOctetsOid => @ifOutOctets + '.' + ifIndex.to_s,
          }
          @ifbandwidth[name] = interface_bandwidth[idx]
          interface_name.delete(name)
        end
      end
    end
    # in case a interface is not found
    if interface_name.size # should be empty if all interfaces are found
      interface_name.each do |name|
        @logger.error("#{self.class.name}, interface #{name} not found ...")
      end
    end
  end

  def init_result
    @result = {}
    @ifname2oids.each_key do |ifname|
      @result[ifname] = {
          :inSpeed => [],
          :outSpeed => [],
          :sample_interval => @option[:interval],
          :received_len => 0,
          :bandwidth_in_bps => @ifbandwidth[ifname] * 1024 * 1024
      }
      @output_target2instance.values.each do |instances|
        instances.each do |instance|
          @result[ifname][:"#{instance}"] = 0
        end
      end
    end
  end

  def cal_speed_status(ifname,interval_len,received_len)
    tmpInArr = @result[ifname][:inSpeed].slice(received_len - interval_len + 1,received_len - 1)
    tmpOutArr = @result[ifname][:outSpeed].slice(received_len - interval_len + 1,received_len - 1)
    case interval_len
      when @short_term_len
        @result[ifname][:"#{"inAvgspeed_in_#{@option[:short_term]}seconds"}"] = tmpInArr.inject{ |r, x| r + x }/ tmpInArr.size
        @result[ifname][:"#{"outAvgspeed_in_#{@option[:short_term]}seconds"}"] = tmpOutArr.inject{ |r, x| r + x }/ tmpOutArr.size
        @result[ifname][:"#{"inBWUtil_in_#{@option[:short_term]}seconds"}"] = @result[ifname][:"#{"inAvgspeed_in_#{@option[:short_term]}seconds"}"].to_f / @result[ifname][:bandwidth_in_bps] * 100
        @result[ifname][:"#{"outBWUtil_in_#{@option[:short_term]}seconds"}"] = @result[ifname][:"#{"outAvgspeed_in_#{@option[:short_term]}seconds"}"].to_f / @result[ifname][:bandwidth_in_bps] * 100
      when @long_term_len
        @result[ifname][:"#{"inAvgspeed_in_#{@option[:long_term]}seconds"}"] = tmpInArr.inject{ |r, x| r + x }/ tmpInArr.size
        @result[ifname][:"#{"outAvgspeed_in_#{@option[:long_term]}seconds"}"] = tmpOutArr.inject{ |r, x| r + x }/ tmpOutArr.size
        @result[ifname][:"#{"inBWUtil_in_#{@option[:long_term]}seconds"}"] = @result[ifname][:"#{"inAvgspeed_in_#{@option[:long_term]}seconds"}"].to_f / @result[ifname][:bandwidth_in_bps] * 100
        @result[ifname][:"#{"outBWUtil_in_#{@option[:long_term]}seconds"}"] = @result[ifname][:"#{"outAvgspeed_in_#{@option[:long_term]}seconds"}"].to_f / @result[ifname][:bandwidth_in_bps] * 100
      else
        @logger.error("#{self.class.name}, calculate speed status error ...")
    end
  end


  def work
    @logger.info("#{self.class.name} is working with configuration #{@option}...")

    @ifname2oids.each_pair do |ifname, ifoids|
      in_and_outBits = []

      #get in and out Bits for an interface
      @get.deal(ifoids.values) do |val|
        in_and_outBits << 8 * val.value.to_i
      end

      cur = Time.now.to_i
      #calculate speed from Bits, and always push it to the right of inspeed and outspeed arrays
      if @result[ifname][:received_len] > 0
        inBits_increased = (in_and_outBits[0] < @result[ifname][:inBits]) ? (in_and_outBits[0] - @result[ifname][:inBits] + 8 * 4294967296) : (in_and_outBits[0] - @result[ifname][:inBits])
        outBits_increased = (in_and_outBits[1] < @result[ifname][:outBits]) ? (in_and_outBits[1] - @result[ifname][:outBits] + 8 * 4294967296) : (in_and_outBits[1] - @result[ifname][:outBits])
        @result[ifname][:inSpeed] << inBits_increased / (cur - @result[ifname][:lastUpdated])
        @result[ifname][:outSpeed] << outBits_increased / (cur - @result[ifname][:lastUpdated])
      else # set first speed to 0
        @result[ifname][:inSpeed] << 0
        @result[ifname][:outSpeed] << 0
      end
      @result[ifname][:lastUpdated] = cur

      #update lastBits
      @result[ifname][:inBits] = in_and_outBits[0]
      @result[ifname][:outBits]= in_and_outBits[1]

      #fixed length array that pop from left and push to right
      case @result[ifname][:received_len]
        when @long_term_len
          #POP from left when len == @long_term_len
          #send BOTH short term and long term results to marmot
          @result[ifname][:inSpeed].delete_at(0)
          @result[ifname][:outSpeed].delete_at(0)
          cal_speed_status(ifname,@short_term_len,@result[ifname][:received_len])
          cal_speed_status(ifname,@long_term_len,@result[ifname][:received_len])
        when @long_term_len - 1
          #DO NOT pop from left when len == @long_term_len - 1
          #But send BOTH short term and long term results to marmot
          @result[ifname][:received_len] = @result[ifname][:received_len] + 1
          cal_speed_status(ifname,@short_term_len,@result[ifname][:received_len])
          cal_speed_status(ifname,@long_term_len,@result[ifname][:received_len])
        when @short_term_len - 1...@long_term_len - 1
          #DO NOT pop when len >= @short_term_len - 1 && len < @long_term_len - 1
          #BUT send short result to marmot
          @result[ifname][:received_len] = @result[ifname][:received_len] + 1
          cal_speed_status(ifname,@short_term_len,@result[ifname][:received_len])
        when 0...@short_term_len - 1
          #DO NOT pop when len < @short_term_len - 1, DO NOT send result to marmot
          @result[ifname][:received_len] = @result[ifname][:received_len] + 1
        else
          @logger.error("#{self.class.name}, maintained data length exceeds for interface #{ifname} ...")
      end
    end

    @result.each_pair do |key, value|
      @logger.info "result: #{key}: #{value}"
    end
    #puts @result
  end

  def migrate
    metrics_list = []
    timestamp = Time.now.to_i.to_s
    #targetprefix = @option[:org_env] + "." + @option[:basetarget] + ".fortigate_#{@option[:cluster_name]}."
    targetprefix = @option[:org_env] + "." + @option[:basetarget] + ".fortigate_#{@option[:cluster_name]}."

    @result.each_pair do |ifname,record|
      @output_target2instance.each_pair do |target, instances|
        instances.each do |instance|
          info = {
              :sn => @option[:basetarget] + "-" + timestamp + "-fgt",
              :target => targetprefix + ifname.to_s + "." + target.to_s,
              :instance => instance.to_s,
              :status => record[instance.to_sym].to_s,
              :details => "Sample interval: #{record[:sample_interval]} seconds, Short term: #{@option[:short_term]} Seconds, Long term: #{@option[:long_term]} Seconds, Link Bandwidth: #{record[:bandwidth_in_bps]/1024/1024} Mbps",
              :timestamp => record[:lastUpdated]*1000,
              :duration => 0,
              :attachments => []
          }
          metrics = Metrics.new(@option[:pin_code], info)
          metrics_list << metrics
        end
      end
      #puts metrics_list
    end
    merged = Metrics.merge(metrics_list)
  end
end