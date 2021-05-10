require_relative '../../lib/agents/agent'
require_relative '../../lib/base/get/sshget'
require_relative '../../lib/base/get/snmpget'
require_relative '../../lib/base/get/snmpbulk'
require_relative '../../data/fortigate-log-filter'

class FgConfig < Agent

  include FortigateLogFilter

  def initialize(option)
    super
    check_option

    @fgVdEntName      = ['1.3.6.1.4.1.12356.101.3.2.1.1.2']   # vdom name
    @fgVdNumber       = ['1.3.6.1.4.1.12356.101.3.1.1.0']     # vdom number

    @sshget = SshGet.new(:ip_address => @option[:ip_address], :username => @option[:username],
                         :options => {:password => @option[:password], :port => @option[:port]})
    @snmpget = SnmpGet.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @snmpbulk = SnmpBulk.new(:ip_address => @option[:ip_address], :community => @option[:community])

    @filterout = FortigateLogFilter::FILTEROUT

    #
    # @result = {
    #     :lastlogindex => {:vdomname1 => 20, :vdomname2 => 2321, ....}
    #     :<vdomname1> => [],
    #     :<vdomname2> => [logentry1, logentry2, ..],
    #     :..
    # }
    @result = {}
  end

  def find_log
    vdoms = vdomlist

    @vdoms_k = []
    vdoms.each do |vd|
      @vdoms_k << vd.to_sym
    end

    # for each vdom, check the vdom's log
    @vdoms_k.each do |vdk|

      # get check line index and log count
      # if it's a procstats startup, just remember the start index (lastlogindex)
      viewlines = -1
      startline = -1
      @sshget.deal(['config vdom',
                    "edit #{vdk.to_s}",
                    "execute log filter device 1",
                    "execute log filter category 1",
                    "execute log filter view-lines 1",
                    "execute log display",
                    'end']) do |out|

        out.split("\n").each do |line|
          m = /(\d+) logs found\.$/.match(line)
          if ! m.nil?
            viewlines = m[1].to_i
            puts "#{vdk} viewlines: #{viewlines}"
            break
          end
        end
      end

      startline = 1

      while(startline < viewlines)
        cmds = ['config vdom',
                "edit #{vdk.to_s}",
                "execute log filter device 1",
                "execute log filter category 1",
                "execute log filter start-line #{startline}",
                "execute log filter view-lines 1000",
                "execute log display",
                'end'
        ]
        startline += 1000
        @sshget.deal(cmds) do |out|
          out.split("\n").each do |line|
            # do filter with filter out hash
            if /^\d+: .*$/.match(line)
              m = /logdesc="(.*?)"/.match(line)
              if ! m.nil?
                if @result[m[1]].nil?
                  @result[m[1]] = 1
                else
                  @result[m[1]] += 1
                end
              else
                puts "no logdesc found. "
              end
            end
          end
        end
      end
    end
    @result.each_key do |key|
      puts "#{key}: #{@result[key]}"
    end
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :username, :password, :cluster_name,
     :basetarget, :pin_code, :org_env, :community, :port].each do |key|
      if !keyset.include? key
        missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end

  def vdomlist
    vdom_number = 0
    @snmpget.deal(@fgVdNumber) do |varbind|
      vdom_number = varbind.value.to_i
    end

    vdoms = []
    @snmpbulk.deal(@fgVdEntName + [0, vdom_number]) do |vditem|
      vdIndex = vditem.name.to_s.split('.')[-1].to_i
      vdoms << vditem.value.to_s
    end

    @logger.info "vdom list: #{vdoms}"
    vdoms
  end
end

agent = FgConfig.new(:ip_address => '10.20.2.41',
                     :community => 'monit_fg',
                     :username => 'networkguest',
                     :password => 'sw6tuswu4rUc',
                     :serial_number => 'fd3000c',
                     :basetarget => 'basetarget',
                     :pin_code => '2342$32&',
                     :org_env => 'bmxcn.allenvs',
                     :cluster_name => 'fg-cl01',
                     :port => 10022)

agent.find_log

agent = FgConfig.new(:ip_address => '10.20.2.42',
                     :community => 'monit_fg',
                     :username => 'networkguest',
                     :password => 'sw6tuswu4rUc',
                     :serial_number => 'fd3000c',
                     :basetarget => 'basetarget',
                     :pin_code => '2342$32&',
                     :org_env => 'bmxcn.allenvs',
                     :cluster_name => 'fg-cl01',
                     :port => 10022)

agent.find_log

agent = FgConfig.new(:ip_address => '10.20.2.43',
                     :community => 'monit_fg',
                     :username => 'networkguest',
                     :password => 'sw6tuswu4rUc',
                     :serial_number => 'fd3000c',
                     :basetarget => 'basetarget',
                     :pin_code => '2342$32&',
                     :org_env => 'bmxcn.allenvs',
                     :cluster_name => 'fg-cl01',
                     :port => 10022)

agent.find_log

# root viewlines: 27600
# bridge viewlines: 443
# mgmt viewlines: 87955
# staging viewlines: 0

# Admin logout successful: 13066
# Super admin left VDOM: 1210
# Admin login successful: 13067
# Configuration changed: 8
# Application crashed: 2
# FortiGate updated: 93
# Admin login failed: 7
# New firmware available on FortiGuard: 1
# Disk log file deleted: 30
# Report generated successfully: 23
# Disk log rolled: 40
# Log rotation requested by forticron: 22
# System configuration backed up by SCP: 159
# Disk log directory deleted: 18
# SNMP query failed: 4
# Attribute configured: 1
# Super admin entered VDOM: 821
# NTP server status changes to reachable: 2
# NTP server status changes to unreachable: 2
# Admin login disabled: 2
# SSL VPN new connection: 40021
# SSL VPN statistics: 33737
# SSL VPN tunnel up: 2545
# SSL VPN exit fail: 27
# SSL VPN alert: 2565
# FortiGuard authentication status: 1231
# SSL VPN tunnel down: 2208
# SSL VPN login fail: 65
# Object attribute configured: 15
# SSL VPN exit error: 5051
# SSL VPN close: 4
# SSL VPN deny: 46
# Object configured: 1
# Authentication timed out: 2

# root viewlines: 25103
# bmetal viewlines: 887
# public viewlines: 361
# iotp viewlines: 0

# Admin login successful: 11944
# Admin logout successful: 11943
# Super admin left VDOM: 956
# FortiGate updated: 94
# Configuration changed: 3
# Super admin entered VDOM: 638
# Application crashed: 1
# Admin login failed: 5
# New firmware available on FortiGuard: 1
# Disk log file deleted: 158
# Report generated successfully: 24
# Log rotation requested by forticron: 24
# Disk log rolled: 166
# System configuration backed up by SCP: 159
# SNMP query failed: 4
# Attribute configured: 1
# Disk log directory deleted: 258
# NTP server status changes to reachable: 1
# NTP server status changes to unreachable: 1
# Object configured: 4
# Object attribute configured: 10
# Admin login disabled: 1

# root viewlines: 24240
# d1 viewlines: 609
# d2 viewlines: 0

# Admin logout successful: 11630
# Admin login successful: 11629
# Super admin left VDOM: 629
# FortiGate updated: 93
# New firmware available on FortiGuard: 1
# Application crashed: 2
# Disk log file deleted: 23
# Report generated successfully: 15
# Disk log rolled: 29
# Log rotation requested by forticron: 15
# System configuration backed up by SCP: 160
# IPsec phase 1 error: 170
# Progress IPsec phase 1: 170
# SNMP query failed: 4
# NTP server status changes to reachable: 2
# NTP server status changes to unreachable: 2
# Configuration changed: 1
# Attribute configured: 1
# Disk log directory deleted: 16
# Super admin entered VDOM: 319
# Admin login disabled: 1
# Admin login failed: 3