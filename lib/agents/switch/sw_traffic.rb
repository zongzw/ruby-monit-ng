require_relative '../../agents/agent'
require_relative '../../base/get/sshget2'
require_relative '../../base/get/snmpwalk'
require_relative '../../base/metrics'

class SwTraffic < Agent
  #
  # option = {
  #     :ip_address => ip,
  #     :community => community,
  #     :interval => @monit_items[item],
  #     :basetarget => base_target,
  #     :pin_code => @pin_code,
  #     :org_env => @org_env,
  #     :username => username,
  #     :password => password,
  # }
  #
  # case item
  #   when 'traffic'
  #     traffic_agent = SwTraffic.new(option)
  #     self.register(traffic_agent)
  #   else
  #     @logger.error "unrecognized monitored item: #{item}"
  # end
  #

  attr_reader :result

  def initialize(option)
    super

    # instead of retrieve information through snmp, we can get the traffic information via 'show interface counters'
    # BUT the way 'show interface counters' runs too slow.
    @ifoids = {
        :IfDescr        => '1.3.6.1.2.1.2.2.1.2',
        :IfOperStatus   => '1.3.6.1.2.1.2.2.1.8', # up(1),  down(2), testing(3)
        :IfInOctet      => '1.3.6.1.2.1.2.2.1.10',
        :IfOutOctet     => '1.3.6.1.2.1.2.2.1.16'
    }

    @vlanoids = {
        :vtpVlanName    => '1.3.6.1.4.1.9.9.46.1.3.1.1.4'
    }

    @exvlan = option[:exvlan]
    @tops = option[:tops]
    @walk = SnmpWalk.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @sshget = SshGet2.new(:ip_address => @option[:ip_address], :username => @option[:username], :password => @option[:password])
    @result = {}
    @origin = {}
  end

  def work
    @logger.info("#{self.class.name} starts to work ...")
    @result = {}

    # after collecting, the format should be like this:
    # {
    #     :interface=>{
    #         "Gi1/0/1"=>{:InOctets=>"411816", :OutOctets=>"35861358", :InSpeed => nnnn, :OutSpeed => mmmm},
    #         "Gi1/0/2"=>{:InOctets=>"412840", :OutOctets=>"35862794", :InSpeed => nnnn, :OutSpeed => mmmm},
    #         ...
    #     },
    #     :ifvl=>{
    #         "Gi1/0/1"=>"1", "Gi1/0/2"=>"1", "Gi1/0/3"=>"1", "Gi1/0/4"=>"1",
    #         ...
    #     },
    #     :vlan=>{"1"=>"default", "2"=>"VLAN0002"}
    # }
    show_interface_counters
    show_interface_status
    snmp_vlan_info

    timestamp = Time.now.to_i
    begin
      @result[:interface].each_pair do |key, value|
        new_inf = {
            :InOctets => value[:InOctets],
            :OutOctets => value[:OutOctets]
        }
        if @origin.empty?
          new_inf[:InSpeed] = new_inf[:OutSpeed] = 0
        else
          originInoctets = originOutoctets = 0
          if ! @origin[:interface][key].nil?
            originInoctets = @origin[:interface][key][:InOctets]
            originOutoctets = @origin[:interface][key][:OutOctets]
          end

          new_inf[:InSpeed] = (value[:InOctets] - originInoctets) / (timestamp - @origin[:timestamp])
          new_inf[:OutSpeed] = (value[:OutOctets] - originOutoctets) / (timestamp - @origin[:timestamp])
          new_inf[:InSpeed] = (new_inf[:InSpeed] < 0) ? 0 : new_inf[:InSpeed]
          new_inf[:OutSpeed] = (new_inf[:OutSpeed] < 0) ? 0 : new_inf[:OutSpeed]
        end

        @result[:interface][key] = new_inf
      end
    ensure
      @origin = {:timestamp => Time.now.to_i, :interface => @result[:interface]}
    end

    # @origin[:interface].each_pair do |key, value|
    #   puts "|#{key}|#{value}|"
    # end
    #puts "=====#{@result[:interface]}"

    # after the following process, the format is like:
    # {
    #     "default":{
    #       "Gi1/0/1":{"InOctets":"437896","OutOctets":"38106849",:InSpeed => nnnn, :OutSpeed => mmmm},
    #       "Gi1/0/2":{"InOctets":"438792","OutOctets":"38109397",:InSpeed => nnnn, :OutSpeed => mmmm},
    #       "Gi1/0/3":{"InOctets":"438792","OutOctets":"38106937",:InSpeed => nnnn, :OutSpeed => mmmm}
    #       ...
    #     },
    #     "VLAN0002":{
    #       "Gi1/0/31":{"InOctets":"127345956","OutOctets":"80703585",:InSpeed => nnnn, :OutSpeed => mmmm},
    #       "Gi1/0/32":{"InOctets":"0","OutOctets":"12122053"},
    #       ...
    #     }
    # }

    tmprlt = {}
    @result[:interface].each_pair  do |key, value|
      #puts "|#{key}|#{value}|"
      ifname = key
      vlanid = @result[:ifvl][ifname]
      if vlanid.nil?
        next
      end
      vlannm = (@result[:vlan][vlanid].nil?) ? vlanid : @result[:vlan][vlanid]

      if tmprlt[vlannm].nil?
        tmprlt[vlannm] = {}
      end
      tmprlt[vlannm][ifname] = value
    end

    @result = tmprlt
    #puts "xyz"
    # @result.each_pair do |key, value|
    #   puts "|#{key}|"
    #   value.each_pair do |ifname, ifvalue|
    #     puts "|#{ifname}|#{ifvalue}|"
    #   end
    # end
  end

  # ibm.allenvs.switch.<ip>.traffic.<vlaname>: top x instance
  def migrate
    metrics_list = []
    timestamp = Time.now.to_i.to_s
    ipstring = @option[:ip_address].gsub '.', '-'

    # @result.each_pair do |key, value|
    #   puts "|#{key}|"
    #   value.each_pair do |ifname, ifvalue|
    #     puts "|#{ifname}|#{ifvalue}|"
    #   end
    # end
    [[:InSpeed, :InOctets], [:OutSpeed, :OutOctets]].each do |item|
      @result.each_pair do |vlannm, vlanvalue|
        #puts "|#{vlannm}|"
        if @exvlan.include? vlannm
          next
        end
        sorted = Hash[vlanvalue.sort_by {|a, b| -b[item[1]].to_i}]
        index = 0
        sorted.each_pair do |ifname, ifvalue|
          if @tops.to_i > 0 && index >= @tops.to_i
            break
          end
          index += 1

          #puts "--#{ifname}, #{ifvalue}"
          info = {
              :sn => ipstring + "-" + timestamp + "-" + ifname,
              :target => @option[:org_env] + "." + @option[:basetarget] +
                  ".#{ipstring}.traffic.#{vlannm}.#{item[0]}",
              :instance => ifname,
              :status => ifvalue[item[0]],
              :details => "top#{index}",
              :timestamp => Time.now().to_i() * 1000,
              :duration => 0,
              :attachments => []
          }
          #puts info
          metrics = Metrics.new(@option[:pin_code], info)
          #puts metrics
          metrics_list << metrics
        end
      end
    end

    merged = Metrics.merge(metrics_list)
  end

  def post_grafana

  end

  def show_interface_counters
    @logger.info("#{self.class.name} starts to get interface traffic information ...")
    icount = 0
    @result[:interface] = {}
    @walk.deal(@ifoids.values) do |row|
      icount += 1
      begin
        new_inf =  {
            :IfDescr => row[0].value.to_s,
            :IfOperStatus => row[1].value.to_i,
            :IfInOctet => row[2].value.to_i,
            :IfOutOctet => row[3].value.to_i
        }
        new_inf[:IfDescr] = new_inf[:IfDescr].sub 'port-channel', 'Po'
        new_inf[:IfDescr] = new_inf[:IfDescr].sub 'GigabitEthernet', 'Gi'
        new_inf[:IfDescr] = new_inf[:IfDescr].sub 'TenGigabitEthernet', 'Te'
        new_inf[:IfDescr] = new_inf[:IfDescr].sub 'FastEthernet', 'Fa'
        new_inf[:IfDescr] = new_inf[:IfDescr].sub 'Ethernet', 'Eth'

        if (new_inf[:IfOperStatus] == 1)
          @result[:interface][new_inf[:IfDescr]] = {:InOctets => new_inf[:IfInOctet], :OutOctets => new_inf[:IfOutOctet]}
        end
      rescue NoMethodError => e
        # just skip the fault ones.
        @logger.warn("NoMethodError #{row}: #{e.message}; #{e.backtrace}")
      end
    end

    @logger.info("Getting interface traffic information finished: #{icount}")
    # it's slow to run 'show interface counters'
    # @result[:interface] = {}
    # @sshget.deal('show interface counters') do |out|
    #   lines = out.split "\r\n"
    #
    #   key = ''
    #   value2 = 0
    #   lines.each do |line|
    #     if line == ''
    #       next
    #     end
    #     if (line =~ /Port\s+InOctets\s+InUcastPkts\s+InMcastPkts\s+InBcastPkts/)
    #       key = :InOctets
    #       value2 = line.index(key.to_s) + key.to_s.length
    #       next
    #     end
    #     if (line =~ /Port\s+OutOctets\s+OutUcastPkts\s+OutMcastPkts\s+OutBcastPkts/)
    #       key = :OutOctets
    #       value2 = line.index(key.to_s) + key.to_s.length
    #       next
    #     end
    #
    #     name1 = 0
    #     name2 = line.index(' ')
    #     value1 = name2
    #     column(line, [[name1, name2], [value1, value2]]) do |values|
    #       if @result[:interface][values[0]].nil?
    #         @result[:interface][values[0]] = {}
    #       end
    #       @result[:interface][values[0]][key] = values[1]
    #     end
    #   end
    # end
  end

  def show_interface_status

    @sshget.deal("show interface status") do |out|

      @result[:ifvl] = {}

      lines = out.split "\n"
      iport = iname = ivlan = iduplex = 0
      lines.each do |line|
        line = line.strip
        if line == '' || ! (line =~ /^-+$/).nil?
          next
        end

        if (line =~ /Port\s+Name\s+Status\s+Vlan\s+Duplex\s+Speed\s+Type/)
          iport = line.index("Port")
          iname = line.index("Name")
          ivlan = line.index("Vlan")
          iduplex = line.index("Duplex")
          next
        end

        port = line[iport...iname].rstrip
        vlan = line[ivlan...iduplex].rstrip

        @result[:ifvl][port] = vlan
      end
    end
  end

  def snmp_vlan_info
    @result[:vlan] = {}
    @walk.deal(@vlanoids.values) do |vlan|
      vlanid = vlan[0].name.to_s.split('.')[-1]
      vlanname = vlan[0].value.to_s
      @result[:vlan][vlanid] = vlanname
    end
  end

  def column(line, pos)
    vs = []
    pos.each do |x, y|
      value = line[x...y].strip
      vs << value
    end
    yield vs
  end
end
