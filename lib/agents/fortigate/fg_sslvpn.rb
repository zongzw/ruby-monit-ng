require_relative '../agent'
require_relative '../../utils/constant'
require_relative '../../base/metrics'
require_relative '../../base/get/snmpwalk'
require_relative '../../base/get/snmpbulk'
require_relative '../../base/get/snmpget'

class FgSslVpn < Agent

=begin
    vpn_agent = FgVpn.new(:ip_address => ip_address,
                                    :community => 'monit_fg',
                                    :serial_number => serial_number,
                                    :tops => tops
                                    :basetarget => base_target,
                                    :pin_code => marmotinfo['pin_code'],
                                    :org_env => marmotinfo['org_env'])
=end

  attr_accessor :lastVpnData
  attr_accessor :currVpnData
  def initialize(option)
    super
    check_option
    @fgVpnSslTunnelIndex    = ['1.3.6.1.4.1.12356.101.12.2.4.1.1']    #ssl vpn tunnel index list
    @fgVpnSslTunnelVdom     = ['1.3.6.1.4.1.12356.101.12.2.4.1.2']    #vdom list the ssl vpn tunnels connected to
    @fgVpnSslTunnelUserName = ['1.3.6.1.4.1.12356.101.12.2.4.1.3']    #ssl vpn tunnel user name list
    @fgVpnSslTunnelUpTime   = ['1.3.6.1.4.1.12356.101.12.2.4.1.6']    #ssl vpn tunnel up-time in seconds
    @fgVpnSslTunnelBytesIn  = ['1.3.6.1.4.1.12356.101.12.2.4.1.7']    #ssl vpn tunnel bytes in list
    @fgVpnSslTunnelBytesOut = ['1.3.6.1.4.1.12356.101.12.2.4.1.8']    #ssl vpn tunnel bytes out list
    @fgVpnSslTunnelSrcIP    = ['1.3.6.1.4.1.12356.101.12.2.4.1.4']    #ssl vpn tunnel source IP

    @fgVdEntIndex           = ['1.3.6.1.4.1.12356.101.3.2.1.1.1']     #vdom index
    @fgVdEntName            = ['1.3.6.1.4.1.12356.101.3.2.1.1.2']     #vdom index and name mapping

    @fgVdColumns = @fgVdEntIndex + @fgVdEntName
    @fgVpnSslTunnelColumns= @fgVpnSslTunnelVdom + @fgVpnSslTunnelUserName + @fgVpnSslTunnelBytesIn + @fgVpnSslTunnelBytesOut + @fgVpnSslTunnelUpTime + @fgVpnSslTunnelSrcIP
    
    @snmpwalk = SnmpWalk.new(:ip_address => @option[:ip_address], :community => @option[:community])

    @tops = option[:tops]

    @lastVpnData = {}
    @currVpnData = {}
    @vdomData = {}   #vdom list on target Fortigate
    @vpnCount = {}   #vpn user count for each vdom

  end

  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :username, :password, :cluster_name, :tops, :basetarget, :pin_code, :org_env, :community].each do |key|
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

    #Get vdom list
    @snmpwalk.deal(@fgVdColumns) do |row|
      vdIndex = row[0].value.to_i
      vdName  = row[1].value.to_s
      @vdomData[vdIndex] = {:vdName => vdName}
    end

    #Get vpn data
    cur = Time.now.to_i
    @snmpwalk.deal(@fgVpnSslTunnelColumns) do |row|
      vpnTunnelVdom = row[0].value.to_i
      vpnTunnelUserName = row[1].value.to_s
      vpnTunnelBytesIn = row[2].value.to_i #* 8 / 1024
      vpnTunnelBytesOut = row[3].value.to_i #* 8 / 1024
      vpnTunnelUpTime = row[4].value.to_i
      vpnTunnelSrcIP  = row[5].value.to_s

      # Use 'vpnTunnelUserName' as key for '@*VpnData' to read and write the ByteIn and ByteOut of certain user.
      # In this case, caution to handle:
      #    1. 'vpnTunnelUserName' is changing over time
      #    2. Duplicated userName in 'vpnTunnelUserName'
      #    3. Calculate speed in case of duplicated username with different BytesIn/BytesOut and uptime value
      # For caution 1, use '@currVpnData' to store current VPN data, and then compare with '@lastVpnData' to determine new user or not, and then calculate Speed
      # For caution 2, the key is to add BytesIn/BytesOut value in different rows belong to same users,
      #                for 'Speed', update the speed value using formula: (a + b - c) / d = (a - c) / d + b / d
      # For caution 3, the key is to add BytesIn/BytesOut value, and uptime value in different rows belong to same users, and then divide them to calculate speed

      if @currVpnData[vpnTunnelUserName].nil? #first shown user in current user list
        currBytesIn = vpnTunnelBytesIn
        currBytesOut = vpnTunnelBytesOut
        currUpTime = vpnTunnelUpTime

        if @lastVpnData[vpnTunnelUserName].nil? # new vpn user for last user list
          currBytesInSpeed = currBytesIn / currUpTime
          currBytesOutSpeed = currBytesOut / currUpTime
        else   #existing vpn user in last user list, calculate speed
          # In case of old session terminated and new session established during the monitoring interval,
          # the BytesIn and BytesOut value reset to nearly zero on Fortigate SSLVPN agent.
          # Use the increasedBytesIn/increasedBytesOut to handle this case.
          increasedBytesIn = (currBytesIn >= @lastVpnData[vpnTunnelUserName][:vpnBytesIn]) ?
              currBytesIn  - @lastVpnData[vpnTunnelUserName][:vpnBytesIn] : currBytesIn
          increasedBytesOut = (currBytesOut >= @lastVpnData[vpnTunnelUserName][:vpnBytesOut]) ?
              currBytesOut - @lastVpnData[vpnTunnelUserName][:vpnBytesOut] : currBytesOut
          currBytesInSpeed = increasedBytesIn  / (cur - @lastVpnData[vpnTunnelUserName][:lastUpdated])
          currBytesOutSpeed = increasedBytesOut / (cur - @lastVpnData[vpnTunnelUserName][:lastUpdated])
        end
      else              #duplicated user in current user list
        currBytesIn = @currVpnData[vpnTunnelUserName][:vpnBytesIn] + vpnTunnelBytesIn
        currBytesOut = @currVpnData[vpnTunnelUserName][:vpnBytesOut] + vpnTunnelBytesOut
        currUpTime = @currVpnData[vpnTunnelUserName][:vpnUpTime] + vpnTunnelUpTime
        if @lastVpnData[vpnTunnelUserName].nil?  # new vpn user for last user list
          currBytesInSpeed = currBytesIn / currUpTime
          currBytesOutSpeed = currBytesOut / currUpTime
        else    #existing user in last user list, but duplicated user in current user list, re-calculate speed using formula: (a + b - c) / d = (a - c) / d + b / d
          currBytesInSpeed = @currVpnData[vpnTunnelUserName][:vpnBytesInSpeed] + vpnTunnelBytesIn / (cur - @lastVpnData[vpnTunnelUserName][:lastUpdated])
          currBytesOutSpeed= @currVpnData[vpnTunnelUserName][:vpnBytesOutSpeed]+ vpnTunnelBytesOut/ (cur - @lastVpnData[vpnTunnelUserName][:lastUpdated])
        end
      end

      @currVpnData[vpnTunnelUserName] = {
          :vpnVdom => @vdomData[vpnTunnelVdom][:vdName],
          :vpnUpTime => currUpTime,
          :vpnBytesIn => currBytesIn,
          :vpnBytesOut => currBytesOut,
          :vpnBytesInSpeed => currBytesInSpeed,
          :vpnBytesOutSpeed => currBytesOutSpeed,
          :vpnSrcIP => vpnTunnelSrcIP,
          :lastUpdated => cur
      }
      #Another version of the above if/else block
      # if @lastVpnData[vpnTunnelUserName].nil? # new vpn user for 'lastVpnData'
      #   if @currVpnData[vpnTunnelUserName].nil? #first shown user in current user list
      #     currBytesIn = vpnTunnelBytesIn
      #     currBytesOut = vpnTunnelBytesOut
      #     currBytesInSpeed = 0
      #     currBytesOutSpeed = 0
      #   else # duplicated user in current user list
      #     currBytesIn = @currVpnData[vpnTunnelUserName][:vpnTunnelBytesIn] + vpnTunnelBytesIn
      #     currBytesOut = @currVpnData[vpnTunnelUserName][:vpnTunnelBytesOut] + vpnTunnelBytesOut
      #     currBytesInSpeed = 0
      #     currBytesOutSpeed = 0
      #   end
      # else #existing vpn user in 'lastVpnData'
      #   if @currVpnData[vpnTunnelUserName].nil? #first shown user in current user list
      #     currBytesIn = vpnTunnelBytesIn
      #     currBytesOut = vpnTunnelBytesOut
      #     currBytesInSpeed = 8 * (vpnTunnelBytesIn  - @lastVpnData[vpnTunnelUserName][:vpnTunnelBytesIn])  / (cur - @lastVpnData[vpnTunnelUserName][:lastUpdated])
      #     currBytesOutSpeed = 8 * (vpnTunnelBytesOut - @lastVpnData[vpnTunnelUserName][:vpnTunnelBytesOut]) / (cur - @lastVpnData[vpnTunnelUserName][:lastUpdated])
      #   else # duplicated user in current user list
      #     currBytesIn = @currVpnData[vpnTunnelUserName][:vpnTunnelBytesIn] + vpnTunnelBytesIn
      #     currBytesOut = @currVpnData[vpnTunnelUserName][:vpnTunnelBytesOut] + vpnTunnelBytesOut
      #     currBytesInSpeed = @currVpnData[vpnTunnelUserName][:vpnTunnelBytesInSpeed] + 8 * vpnTunnelBytesIn / (cur - @lastVpnData[vpnTunnelUserName][:lastUpdated])
      #     currBytesOutSpeed= @currVpnData[vpnTunnelUserName][:vpnTunnelBytesOutSpeed]+ 8 * vpnTunnelBytesOut/ (cur - @lastVpnData[vpnTunnelUserName][:lastUpdated])
      #   end
      # end


    end

    @logger.info "result: "
    @currVpnData.each_pair do |key, value|
      @logger.info "#{key}: #{value}"
    end

    #update @lastVpnData and @currVpnData
    @lastVpnData = @currVpnData
    @currVpnData = {}

    #Calculate VPN count
    vpncount = {}
    @lastVpnData.each_pair do |userName, record|
      vdomName = record[:vpnVdom]
      next if vdomName.nil?
      count = (vpncount[vdomName].nil?) ? 1 : vpncount[vdomName][:count] + 1
      vpncount[vdomName] = {
          :count => count,
          :lastUpdated => record[:lastUpdated]
      }
    end
    @vpnCount = vpncount
  end

  def migrate
    timestamp = Time.now.to_i.to_s
    metrics_list = []

    target = @option[:org_env] + "." + @option[:basetarget] + ".#{@option[:cluster_name]}.vpnstat."

    [[:vpnBytesInSpeed, :vpnBytesIn], [:vpnBytesOutSpeed, :vpnBytesOut]].each do |item|
      sorted = Hash[@lastVpnData.sort_by {|userName, record| -record[item[1]].to_i}]
      index = 0
      sorted.each_pair do |userName, record|
        break if index >= @tops.to_i
        index += 1
        info = {
            :sn => @option[:cluster_name] + "-" + timestamp + "-vpnstat-#{item[0].to_s}-top-#{@tops}-sorted-by-#{item[1].to_s}",
            :target => target + "#{item[0]}",
            :instance => userName,
            :status => record[item[0]].to_i,
            :details => "top#{index} #{item[1]} in Bytes, #{record[item[1]].to_i} bytes in total. Speed is in Bytes/s. Tunnel Source IP is #{record[:vpnSrcIP].to_s}",
            :timestamp => record[:lastUpdated]*1000,
            :duration => 0,
            :attachments => []
        }
        metrics = Metrics.new(@option[:pin_code], info)
        metrics_list << metrics
      end
    end

    #vpnCount
    @vpnCount.each_pair do |vdom, record|
      info = {
          :sn => @option[:cluster_name] + "-" + timestamp + "-vpnstat-vpnCount-all",
          :target => target + "vpnCount",
          :instance => vdom,
          :status => record[:count].to_i,
          :details => "The number of SSL VPN connections",
          :timestamp => record[:lastUpdated]*1000,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics
    end

    merged = Metrics.merge(metrics_list)
  end


end












