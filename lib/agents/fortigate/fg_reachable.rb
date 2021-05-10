#DEPRECATED
require_relative '../agent'
require_relative '../../base/get/snmpget'
require_relative '../../base/get/sshget'


# deprecated: unknown bug due to sshget. sometimes it reports:
#      undefined method 'update' for #
# changed to use fg_reachable2.rb instead.

class FgReachable < Agent

  attr_reader :result
  def initialize(option)
    super

    @sshget = SshGet.new(:ip_address => option[:ip_address], :username => option[:username], :options => {:password => option[:password], :port => option[:port]})
    @snmpget = SnmpGet.new(:ip_address => @option[:ip_address], :community => @option[:community])

    @testoids = '1.3.6.1.2.1.1.3.0' # sysUpTime
    @result = {}
  end

  def work
    @logger.info("#{self.class.name} is working")
    @result = {}

    begin
      @result[:snmp] = {}
      @snmpget.deal([@testoids]) do |varbind|
        @result[:snmp][:status] = 0
        @result[:snmp][:details] = varbind.value.to_s
        @logger.info("snmp get: #{varbind.value.to_s}")
      end
    rescue => e
      @result[:snmp][:status] = -1
      @result[:snmp][:details] = "#{e.message}"
      @logger.error("snmp failed to get: #{e.class.name}: #{e.message}")
      @logger.error("backtrace: #{e.backtrace}")
    end

    begin
      @result[:ssh] = {}
      @sshget.deal(["get system status"]) do |out|
        lines = out.split('\r\n')
        lines.each do |line|
          if /^System time: (.*)$/.match(line)
            @result[:ssh][:status] = 0
            @result[:ssh][:details] = $1
            @logger.debug("ssh get: #{line}")
          else
            @logger.error("Not found: System time line.")
          end
        end
      end
    rescue => e
      @result[:ssh][:status] = -1
      @result[:ssh][:details] = "#{e.message}"
      @logger.error("ssh get failed: #{e.class.name}: #{e.message}")
      @logger.error("backtrace: #{e.backtrace}")
    end

  end

  # bmxcn.allenvs.fortigate.<cluster name>.reachable
  def migrate
    metrics_list = []
    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]

    [:ssh, :snmp].each do |item|
      info = {
          :sn => @option[:cluster_name] + timestamp,
          :target => targetprefix + ".#{@option[:cluster_name]}.reachable",
          :instance => item,
          :status => @result[item][:status],
          :details => @result[item][:details],
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }

      metrics = Metrics.new(@option[:pin_code], info)
      #puts metrics
      metrics_list << metrics

    end
    merged = Metrics.merge(metrics_list)
  end
end