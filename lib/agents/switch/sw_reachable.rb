# DEPRECATED
# Replaced by new job: agent-mon 2017.10.19

require_relative '../agent'
require_relative '../../base/get/snmpget'
require_relative '../../base/get/sshget2'

class SwReachable < Agent

  attr_reader :result
  def initialize(option)
    super

    @sshget = SshGet2.new(:ip_address => option[:ip_address], :username => option[:username], :password => option[:password])
    @snmpget = SnmpGet.new(:ip_address => @option[:ip_address], :community => @option[:community])

    @testoids = '1.3.6.1.2.1.1.3.0' # sysUpTime
    @result = {}
  end

  def work
    @result = {}

    begin
      @result[:snmp] = {}
      @snmpget.deal([@testoids]) do |varbind|
        @result[:snmp][:status] = 0
        @result[:snmp][:details] = varbind.value.to_s
      end
    rescue => e
      @result[:snmp][:status] = -1
      @result[:snmp][:details] = "#{e.message}"
      @logger.error "#{e.class.name}: #{e.message}; #{e.backtrace}"
    end

    begin
      @result[:ssh] = {}
      @sshget.deal(["show clock"]) do |out|
        @result[:ssh][:status] = 0
        @result[:ssh][:details] = out
      end
    rescue => e
      @result[:ssh][:status] = -1
      @result[:ssh][:details] = "#{e.message}"
      @logger.error "#{e.class.name}: #{e.message}; #{e.backtrace}"
    end

  end

  # bmxcn.allenvs.switch.<ipstring>.reachable
  def migrate
    metrics_list = []
    timestamp = Time.now.to_i.to_s
    ipstring = @option[:ip_address].gsub '.', '-'
    targetprefix = @option[:org_env] + "." + @option[:basetarget]

    [:ssh, :snmp].each do |item|
      info = {
          :sn => ipstring + '-' + timestamp,
          :target => targetprefix + ".#{ipstring}.reachable",
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